-- Teste para contratação de analista / desenvolvedor(a) SQL

-- Realize um `fork` e suba o código desenvolvido dentro deste repositório.

/* Introdução
  - Cria a base de dados no seu SQL local usando o script `database-script.sql`;
  - Verifique se todo o schema, tabelas e dados foram criados;
  - Construa os scripts, queries e procedures para cada questão abaixo:
  - Armazene os scripts em um novo arquivo `.sql` com as construções.
*/


-- ### Questões para construir
--01. Crie uma query que obtenha a lista de produtos (ProductName), e a quantidade por unidade (QuantityPerUnit);
SELECT ProductName, QuantityPerUnit
FROM Products;
------------------------------------------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------------------------------------------

--02. Crie uma query que obtenha a lista de produtos ativos (ProductID e ProductName);
SELECT ProductID, ProductName
FROM Products
WHERE Discontinued = 0;
------------------------------------------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------------------------------------------

--03. Crie uma query que obtenha a lista de produtos descontinuados (ProductID e ProductName);
SELECT ProductID, ProductName
FROM Products
WHERE Discontinued = 1;
------------------------------------------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------------------------------------------

--04. Crie uma query que obtenha a lista de produtos (ProductID, ProductName, UnitPrice) ativos, onde o custo dos produtos são menores que $20;
SELECT ProductID, ProductName, UnitPrice
FROM Products
WHERE Discontinued = 0 AND UnitPrice < 20;
------------------------------------------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------------------------------------------

--05. Crie uma query que obtenha a lista de produtos (ProductID, ProductName, UnitPrice) ativos, onde o custo dos produtos são entre $15 e $25;
SELECT ProductID, ProductName, UnitPrice
FROM Products
WHERE Discontinued = 0 AND UnitPrice BETWEEN 15 AND 25;
------------------------------------------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------------------------------------------

--06. Crie uma query que obtenha a lista de produtos (ProductName, UnitPrice) que tem preço acima da média;
SELECT ProductName, UnitPrice
FROM Products
WHERE UnitPrice > (SELECT AVG(UnitPrice) FROM Products);
GO
------------------------------------------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------------------------------------------

--07. Crie uma procedure que retorne cada produto e seu preço;
CREATE PROCEDURE sp_ProdutosPrecos
AS
SELECT ProductID, ProductName, UnitPrice
FROM Products;
GO
-- Chamada da Procedure sp_ProdutosPrecos 
exec sp_ProdutosPrecos;
GO 

-- Adicione à procedure, criada na questão anterior, os parâmetros 'Codigo_Fornecedor' (permitindo escolher 1 ou mais) e 'Codigo_Categoria' (permitindo escolher 1 ou mais) e altere-a para atender a passagem desses parâmetros;
CREATE OR ALTER PROCEDURE sp_ProdutosPrecos
    @Codigo_Fornecedor VARCHAR(MAX) = NULL,
    @Codigo_Categoria VARCHAR(MAX) = NULL 
AS
BEGIN
    -- Remove espaços em branco
    SET @Codigo_Fornecedor = REPLACE(@Codigo_Fornecedor, ' ', '')
    SET @Codigo_Categoria = REPLACE(@Codigo_Categoria, ' ', '')

    SELECT ProductID, ProductName, UnitPrice
    FROM Products
    WHERE
        (@Codigo_Fornecedor IS NULL OR 
         CHARINDEX(',' + CAST(SupplierID AS VARCHAR(10)) + ',', ',' + @Codigo_Fornecedor + ',') > 0)
        AND
        (@Codigo_Categoria IS NULL OR 
         CHARINDEX(',' + CAST(CategoryID AS VARCHAR(10)) + ',', ',' + @Codigo_Categoria + ',') > 0)
END;
GO
-- Chamada da Procedure sp_ProdutosPrecos 
EXEC sp_ProdutosPrecos @Codigo_Fornecedor = '1,2', @Codigo_Categoria = '1,2';
GO

-- Adicione à procedure, criada na questão anterior, o parâmetro 'Codigo_Transportadora' (permitindo escolher 1 ou mais) e um outro parâmetro 'Tipo_Saida' para se optar por uma saída OLTP (Transacional) ou OLAP (Pivot).
CREATE OR ALTER PROCEDURE sp_ProdutosPrecos
    @Codigo_Fornecedor VARCHAR(MAX) = NULL,
    @Codigo_Categoria VARCHAR(MAX) = NULL,
    @Codigo_Transportadora VARCHAR(MAX) = NULL,
    @Tipo_Saida VARCHAR(10) = 'OLTP' -- 'OLTP' ou 'OLAP'
AS
BEGIN

    IF @Tipo_Saida = 'OLAP'
    BEGIN
        -- OLAP: sumarização de vendas por produto
        SELECT 
            p.ProductID,
            p.ProductName,
            SUM(od.Quantity * od.UnitPrice * (1 - od.Discount)) AS TotalVendido
        FROM Products p
        JOIN [Order Details] od ON p.ProductID = od.ProductID
        JOIN Orders o ON o.OrderID = od.OrderID
        WHERE
            (@Codigo_Fornecedor IS NULL OR CHARINDEX(',' + CAST(p.SupplierID AS VARCHAR) + ',', ',' + @Codigo_Fornecedor + ',') > 0)
            AND (@Codigo_Categoria IS NULL OR CHARINDEX(',' + CAST(p.CategoryID AS VARCHAR) + ',', ',' + @Codigo_Categoria + ',') > 0)
            AND (@Codigo_Transportadora IS NULL OR CHARINDEX(',' + CAST(o.ShipVia AS VARCHAR) + ',', ',' + @Codigo_Transportadora + ',') > 0)
        GROUP BY p.ProductID, p.ProductName
        ORDER BY p.ProductID;
    END
    ELSE
    BEGIN
        -- OLTP: produtos detalhados
        SELECT 
            p.ProductID, 
            p.ProductName, 
            p.UnitPrice
        FROM Products p
        WHERE
            (@Codigo_Fornecedor IS NULL OR CHARINDEX(',' + CAST(p.SupplierID AS VARCHAR) + ',', ',' + @Codigo_Fornecedor + ',') > 0)
            AND (@Codigo_Categoria IS NULL OR CHARINDEX(',' + CAST(p.CategoryID AS VARCHAR) + ',', ',' + @Codigo_Categoria + ',') > 0);
    END
END;
GO

/* -- Chamada da Procedure sp_ProdutosPrecos  */
-- Exemplo de chamada OLAP:
exec sp_ProdutosPrecos @Codigo_Fornecedor = '1,2', @Codigo_Categoria = '1,2', @Codigo_Transportadora = '1,2', @Tipo_Saida = 'OLAP';

-- Exemplo de chamada OLTP:
exec sp_ProdutosPrecos @Codigo_Fornecedor = '1,2', @Codigo_Categoria = '1,2', @Codigo_Transportadora = '1', @Tipo_Saida = 'OLTP';

------------------------------------------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------------------------------------------

--08. Crie uma query que obtenha a lista de empregados e seus liderados, caso o empregado não possua liderado, informar 'Não possui liderados'.
SELECT 
    e1.EmployeeID AS Empregado,
    e1.LastName + ', ' + e1.FirstName AS Nome,
    ISNULL(CAST(e2.EmployeeID AS VARCHAR), 'Não possui liderados') AS LideradoID,
    ISNULL(e2.LastName + ', ' + e2.FirstName, 'Não possui liderados') AS NomeLiderado
FROM Employees e1
LEFT JOIN Employees e2 ON e2.ReportsTo = e1.EmployeeID
ORDER BY e1.EmployeeID, e2.EmployeeID;
------------------------------------------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------------------------------------------

-- 09. Crie uma query que obtenha o(s) produto(s) mais caro(s) e o(s) mais barato(s) da lista (ProductName e UnitPrice);
SELECT ProductName, UnitPrice
FROM Products
WHERE UnitPrice = (SELECT MAX(UnitPrice) FROM Products)
   OR UnitPrice = (SELECT MIN(UnitPrice) FROM Products);
------------------------------------------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------------------------------------------

-- 10. Crie uma query que obtenha a lista de pedidos dos funcionários da região 'Western';
SELECT 
    o.OrderID,
    o.OrderDate,
    e.EmployeeID,
    e.FirstName + ' ' + e.LastName AS EmployeeName,
    r.RegionDescription AS Region
FROM orders o
INNER JOIN employees e ON o.EmployeeID = e.EmployeeID
INNER JOIN employeeterritories et ON e.EmployeeID = et.EmployeeID
INNER JOIN territories t ON et.TerritoryID = t.TerritoryID
INNER JOIN region r ON t.RegionID = r.RegionID
WHERE r.RegionDescription = 'Western'
ORDER BY o.OrderDate;
------------------------------------------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------------------------------------------

-- 11. Crie uma query que obtenha os números de pedidos e a lista de clientes (CompanyName, ContactName, Address e Phone), que possuam 171 como código de área do telefone e que o frete dos pedidos custem entre $6.00 e $13.00;
SELECT 
    o.OrderID,
    c.CompanyName,
    c.ContactName,
    c.Address,
    c.Phone
FROM orders o
INNER JOIN customers c ON o.CustomerID = c.CustomerID
WHERE 
    o.Freight BETWEEN 6.00 AND 13.00
    AND c.Phone LIKE '(171)%'
ORDER BY o.OrderID;
------------------------------------------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------------------------------------------

-- 14. Crie uma query que obtenha todos os dados de pedidos (Orders) que envolvam os fornecedores da cidade 'Manchester' e foram enviados pela empresa 'Speedy Express';
SELECT DISTINCT o.*
FROM orders o
INNER JOIN shippers s ON o.ShipVia = s.ShipperID
INNER JOIN [Order Details] od ON o.OrderID = od.OrderID --- TABELA COM ESPAÇO NO NOME [Order Details]
INNER JOIN products p ON od.ProductID = p.ProductID
INNER JOIN suppliers sup ON p.SupplierID = sup.SupplierID
WHERE 
    sup.City = 'Manchester'
    AND s.CompanyName = 'Speedy Express'
ORDER BY o.OrderID;
------------------------------------------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------------------------------------------

-- 15. Crie uma query que obtenha a lista de Produtos (ProductName) constantes nos Detalhe dos Pedidos (Order Details), calculando o valor total de cada produto já aplicado o desconto % (se tiver algum);
SELECT 
    p.ProductName,
    SUM(od.UnitPrice * od.Quantity * (1 - od.Discount)) AS TotalVendido
FROM [Order Details] od
INNER JOIN products p ON od.ProductID = p.ProductID
GROUP BY p.ProductName
ORDER BY TotalVendido DESC;

------------------------------------------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------------------------------------------


/*
### Modelo de Dados:
<img width="1121" alt="Modelo de Dados" src="https://github.com/targetsoftware/teste-contratacao-sql/assets/9052611/bc869bf2-615e-4619-a017-1aebc5ea11f8">

### Questões complementares:
  1. Tem conhecimento em processos e ferramentas de ETL? Quantos anos de experiência? Quais cases foram aplicados?
  R: Sim, possuo conhecimento sólido em processos e ferramentas de ETL, com mais de 14 anos de experiência, atuando desde 2010 com Pentaho BI, SQL Server Integration Services (SSIS) e Informatica PowerCenter.
	  Ao longo da minha trajetória, participei de diversos projetos de migração e integração de dados nas áreas contábil, fiscal e de folha de pagamento, com destaque para:
		* Migração de dados de sistemas legados para ERPs modernos nas áreas contábil e fiscal, garantindo consistência, conformidade tributária e histórico completo das movimentações.
		* Processos ETL para folha de pagamento, envolvendo extração de dados de múltiplas fontes (bancos, arquivos e sistemas externos), transformação conforme regras de negócio trabalhista e carga em ambientes analíticos para geração de relatórios e auditorias.
		* Utilização de Pentaho BI para integração de dados financeiros, alimentando dashboards e cubos OLAP para diretoria.
		* Projetos com SSIS em rotinas de ETL incremental, controle de erros, versionamento de dados e monitoramento de cargas para atender requisitos de compliance e SLA.


  2. Tem experiência com ferramental Azure Data Factory?
  R: Sim, tenho experiência com o Azure Data Factory (ADF), atuando na orquestração de pipelines de dados em nuvem, especialmente em projetos de migração e integração de dados contábeis, fiscais e de folha de pagamento.
	  Utilizei o ADF para:	
		* Criar pipelines para extração de dados de ambientes on-premises e fontes como SQL Server, Oracle e arquivos CSV no Data Lake.
		* Aplicar transformações usando Data Flows e integração com Azure Synapse Analytics para modelagem de dados e geração de relatórios.
		* Automatizar rotinas de ETL com gatilhos (triggers), controle de execução por parâmetros, monitoramento via logs nativos e gerenciamento de falhas com alertas no Azure Monitor.
		* Trabalhar com Linked Services, integration runtimes e gerenciamento de credenciais com Key Vault.

  3. Pode responder em um fluxograma (ou escrito em tópicos) um case de ETL onde:
      - Parte dos dados da origem estão em banco de dados Oracle e outra em CSV no Storage Bucket da AWS
      - O dado final deverá estar na base de dados SQL Server.
      - Deverá acontecer validação da entrada dos dados da origem.
      - Validação dos dados finais que foram processados.
      - Cálculos dos dados de origem, para geração de indicadores (que serão os dados finais).
	R: Apresentação do Case 
		1. Fontes de Dados:
			 Banco Oracle: Tabelas com dados financeiros (ex: lançamentos contábeis e fiscais).
			 CSV no AWS S3: Planilhas de folha de pagamento exportadas mensalmente.

		2. Ferramentas Utilizadas:
			 Azure Data Factory (ADF) ou Pentaho Data Integration (PDI) como orquestrador ETL.
			 Conectores: JDBC para Oracle, conector S3 (via API) para CSV, OLEDB para SQL Server.

		3. Processo ETL (Tópicos):
		[Extração]:
			 Conectar ao Oracle → extrair dados de tabelas (com filtros por data e status).
			 Conectar ao S3 → baixar e ler arquivos CSV de folha (com schema definido).

		[Validação de Entrada]:
			 Validar estrutura dos arquivos CSV (colunas esperadas, tipos e registros obrigatórios).
			 Validar dados Oracle (ex: lançamentos sem contas contábeis são rejeitados).
			 Logs de erros salvos em tabela de controle.

		[Transformação]:
			 Conversão de formatos (datas, códigos).
			 Join entre dados de Oracle e folha (matrículas, centro de custo).
			 Aplicação de regras de negócio (ex: cálculo de encargos, agregações).

		[Geração de Indicadores]:
			 Cálculo de:
				  Total de encargos por departamento.
				  Percentual de despesas operacionais vs. receita.
				  Média de custo por colaborador por unidade.
			 Geração de tabela de indicadores consolidados.

		[Validação de Saída]: 
			 Comparação de totais entre entrada e saída.
			 Checagem de integridade referencial (dimensões x fatos).
			 Criação de log de sucesso/erro por batch.

		[Carga no SQL Server]: 
			 Truncate + Insert em staging.
			 Carga final nas tabelas dimensionais e de indicadores.
			 Envio de e-mail de status e logs para a equipe.
------------------------------------------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------------------------------------------


### O que será avaliado:
  - Padrão utilizado de desenvolvimento;
  - Boas práticas aplicadas;
  - Aplicação de conceitos de performance;
  - Organização e desenho do processo de ETL.

### Diferenciais
  - Documentação
  - Azure DataFactory

Disponibilizar o código desenvolvido via GitHub (realize um `fork` deste repositório) para avaliação. 

Para comunicação, caso não tenha recebido algum contato, notifique rh@targetsoftware.com.br sobre a finalização do teste com o link do repositório.
*/