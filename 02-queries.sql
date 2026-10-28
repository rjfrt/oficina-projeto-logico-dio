-- =====================================================
-- Oficina Mecânica | Parte 2: queries
-- Execute UMA query por vez (no DB Fiddle, painel de baixo "Query SQL").
-- Cada query traz a pergunta de negócio que ela responde e as
-- cláusulas usadas.
-- =====================================================


-- Q1. Quais serviços a oficina oferece e quanto cobra de mão de obra?
-- [SELECT simples, ORDER BY]
SELECT id_servico, descricao, valor_mao_de_obra
FROM servico
ORDER BY descricao;


-- Q2. Quais peças custam mais de R$ 100,00 e quantas há em estoque?
-- [WHERE, ORDER BY]
SELECT descricao, valor_unitario, quantidade_estoque
FROM peca
WHERE valor_unitario > 100
ORDER BY valor_unitario DESC;


-- Q3. Quem são os mecânicos de cada equipe e qual a especialidade deles?
-- [JOIN, ORDER BY]
SELECT e.nome_equipe, m.codigo, m.nome, m.especialidade
FROM equipe e
JOIN mecanico m ON m.id_equipe = e.id_equipe
ORDER BY e.nome_equipe, m.nome;


-- Q4. Quais veículos cada cliente possui e qual a idade de cada um?
-- [atributo derivado (idade do veículo), JOIN, ORDER BY]
SELECT c.nome AS cliente, v.placa, CONCAT(v.marca, ' ', v.modelo) AS veiculo,
       v.ano_fabricacao,
       YEAR(CURDATE()) - v.ano_fabricacao AS idade_anos
FROM cliente c
JOIN veiculo v ON v.id_cliente = c.id_cliente
ORDER BY idade_anos DESC;


-- Q5. Qual o prazo (em dias) combinado com o cliente em cada OS?
-- [atributo derivado (DATEDIFF), JOIN, ORDER BY]
SELECT o.numero_os, c.nome AS cliente, v.modelo, o.tipo,
       DATE(o.data_emissao) AS emissao,
       o.data_conclusao_prevista AS entrega_prevista,
       DATEDIFF(o.data_conclusao_prevista, DATE(o.data_emissao)) AS prazo_dias
FROM ordem_servico o
JOIN veiculo v ON v.id_veiculo = o.id_veiculo
JOIN cliente c ON c.id_cliente = v.id_cliente
ORDER BY prazo_dias DESC, o.numero_os;


-- Q6. Quantas OS cada cliente já abriu (inclusive quem nunca abriu nenhuma)?
-- [LEFT JOIN, GROUP BY, ORDER BY]
SELECT c.id_cliente, c.nome AS cliente, COUNT(o.numero_os) AS qtd_os
FROM cliente c
LEFT JOIN veiculo v       ON v.id_cliente = c.id_cliente
LEFT JOIN ordem_servico o ON o.id_veiculo = v.id_veiculo
GROUP BY c.id_cliente, c.nome
ORDER BY qtd_os DESC, cliente;


-- Q7. Quais clientes abriram mais de uma OS?
-- [JOIN, GROUP BY, HAVING]
SELECT c.nome AS cliente, COUNT(o.numero_os) AS qtd_os
FROM cliente c
JOIN veiculo v       ON v.id_cliente = c.id_cliente
JOIN ordem_servico o ON o.id_veiculo = v.id_veiculo
GROUP BY c.id_cliente, c.nome
HAVING COUNT(o.numero_os) > 1
ORDER BY qtd_os DESC;


-- Q8. Como o valor de cada OS se divide entre mão de obra e peças, e o total bate?
-- [atributos derivados, subconsultas com GROUP BY, LEFT JOIN, CASE]
SELECT o.numero_os,
       COALESCE(s.mao_de_obra, 0) AS total_mao_de_obra,
       COALESCE(p.pecas, 0)       AS total_pecas,
       COALESCE(s.mao_de_obra, 0) + COALESCE(p.pecas, 0) AS total_calculado,
       o.valor_total,
       CASE WHEN COALESCE(s.mao_de_obra, 0) + COALESCE(p.pecas, 0) = o.valor_total
            THEN 'OK' ELSE 'DIVERGENTE' END AS conferencia
FROM ordem_servico o
LEFT JOIN (SELECT numero_os, SUM(quantidade * valor_unitario) AS mao_de_obra
           FROM os_servico GROUP BY numero_os) s ON s.numero_os = o.numero_os
LEFT JOIN (SELECT numero_os, SUM(quantidade * valor_unitario) AS pecas
           FROM os_peca GROUP BY numero_os) p ON p.numero_os = o.numero_os
ORDER BY o.numero_os;


-- Q9. Quais equipes faturaram mais de R$ 1.100,00 em OS autorizadas?
-- [JOIN, WHERE, GROUP BY, HAVING, atributo derivado (média), ORDER BY]
SELECT e.nome_equipe,
       COUNT(o.numero_os)        AS qtd_os,
       SUM(o.valor_total)        AS faturamento,
       ROUND(AVG(o.valor_total), 2) AS ticket_medio
FROM equipe e
JOIN ordem_servico o ON o.id_equipe = e.id_equipe
WHERE o.autorizada = TRUE
GROUP BY e.id_equipe, e.nome_equipe
HAVING SUM(o.valor_total) > 1100
ORDER BY faturamento DESC;


-- Q10. Quais serviços são mais executados (apenas em OS autorizadas)?
-- [JOIN, WHERE, GROUP BY, ORDER BY]
SELECT sv.descricao, SUM(os.quantidade) AS vezes_executado,
       SUM(os.quantidade * os.valor_unitario) AS receita_mao_de_obra
FROM os_servico os
JOIN servico sv       ON sv.id_servico = os.id_servico
JOIN ordem_servico o  ON o.numero_os   = os.numero_os
WHERE o.autorizada = TRUE
GROUP BY sv.id_servico, sv.descricao
ORDER BY vezes_executado DESC, receita_mao_de_obra DESC;


-- Q11. Quais peças já foram usadas 3 vezes ou mais (em unidades) e quanto sobra em estoque?
-- [JOIN, WHERE, GROUP BY, HAVING, ORDER BY]
SELECT pc.descricao, SUM(op.quantidade) AS unidades_usadas, pc.quantidade_estoque
FROM os_peca op
JOIN peca pc         ON pc.id_peca  = op.id_peca
JOIN ordem_servico o ON o.numero_os = op.numero_os
WHERE o.autorizada = TRUE
GROUP BY pc.id_peca, pc.descricao, pc.quantidade_estoque
HAVING SUM(op.quantidade) >= 3
ORDER BY unidades_usadas DESC;


-- Q12. Quais OS estão aguardando autorização do cliente e de quem são?
-- [JOIN de várias tabelas, WHERE, ORDER BY]
SELECT o.numero_os, c.nome AS cliente, c.telefone, v.placa,
       e.nome_equipe, o.valor_total, o.data_conclusao_prevista
FROM ordem_servico o
JOIN veiculo v ON v.id_veiculo = o.id_veiculo
JOIN cliente c ON c.id_cliente = v.id_cliente
JOIN equipe e  ON e.id_equipe  = o.id_equipe
WHERE o.status = 'AGUARDANDO_AUTORIZACAO'
ORDER BY o.data_conclusao_prevista;


-- Q13. As OS concluídas saíram no prazo, atrasadas ou antecipadas?
-- [atributos derivados (DATEDIFF + CASE), WHERE, ORDER BY]
SELECT o.numero_os, o.data_conclusao_prevista, o.data_conclusao_real,
       DATEDIFF(o.data_conclusao_real, o.data_conclusao_prevista) AS dias_de_diferenca,
       CASE
           WHEN o.data_conclusao_real > o.data_conclusao_prevista THEN 'ATRASADA'
           WHEN o.data_conclusao_real < o.data_conclusao_prevista THEN 'ANTECIPADA'
           ELSE 'NO PRAZO'
       END AS situacao
FROM ordem_servico o
WHERE o.data_conclusao_real IS NOT NULL
ORDER BY dias_de_diferenca DESC;


-- Q14. Quais peças do estoque não cobrem as OS ainda em andamento?
-- [JOIN, WHERE, GROUP BY, HAVING comparando com coluna do grupo, atributo derivado]
SELECT pc.descricao,
       SUM(op.quantidade)                         AS necessario,
       pc.quantidade_estoque                      AS em_estoque,
       SUM(op.quantidade) - pc.quantidade_estoque AS faltam
FROM os_peca op
JOIN peca pc         ON pc.id_peca  = op.id_peca
JOIN ordem_servico o ON o.numero_os = op.numero_os
WHERE o.status IN ('AGUARDANDO_AUTORIZACAO','AUTORIZADA','EM_EXECUCAO')
GROUP BY pc.id_peca, pc.descricao, pc.quantidade_estoque
HAVING SUM(op.quantidade) > pc.quantidade_estoque;


-- Q15. Quais mecânicos atuaram em cada OS (a equipe da OS inteira)?
-- [JOIN de várias tabelas, GROUP_CONCAT, GROUP BY, ORDER BY]
SELECT o.numero_os, c.nome AS cliente, v.modelo, e.nome_equipe,
       GROUP_CONCAT(m.nome ORDER BY m.nome SEPARATOR ', ') AS mecanicos,
       o.status
FROM ordem_servico o
JOIN veiculo v  ON v.id_veiculo = o.id_veiculo
JOIN cliente c  ON c.id_cliente = v.id_cliente
JOIN equipe e   ON e.id_equipe  = o.id_equipe
JOIN mecanico m ON m.id_equipe  = e.id_equipe
GROUP BY o.numero_os, c.nome, v.modelo, e.nome_equipe, o.status
ORDER BY o.numero_os;


-- Q16. Qual o ticket médio de revisões e de consertos (sem contar OS canceladas)?
-- [WHERE, GROUP BY, atributos derivados (AVG/SUM), ORDER BY]
SELECT tipo, COUNT(*) AS qtd_os, ROUND(AVG(valor_total), 2) AS ticket_medio, SUM(valor_total) AS total
FROM ordem_servico
WHERE status <> 'CANCELADA'
GROUP BY tipo
ORDER BY ticket_medio DESC;


-- TESTE DE REGRA (deve FALHAR): a OS 6 ainda não foi autorizada pelo cliente.
-- UPDATE ordem_servico SET status = 'EM_EXECUCAO' WHERE numero_os = 6;
