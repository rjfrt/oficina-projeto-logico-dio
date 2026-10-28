-- =====================================================
-- Oficina Mecânica | Projeto lógico (MySQL 8.0.16+)
-- Parte 1: criação do esquema + persistência de dados de teste
-- Sem CREATE DATABASE/USE: pode ser colado direto no DB Fiddle
-- (painel de cima, "Schema SQL").
-- =====================================================

-- ---------- CLIENTE ----------
CREATE TABLE cliente (
    id_cliente INT AUTO_INCREMENT PRIMARY KEY,
    nome       VARCHAR(100) NOT NULL,
    cpf        CHAR(11) NOT NULL UNIQUE,
    telefone   VARCHAR(20),
    email      VARCHAR(120),
    endereco   VARCHAR(200)
);

-- ---------- VEÍCULO (1 cliente : N veículos) ----------
CREATE TABLE veiculo (
    id_veiculo     INT AUTO_INCREMENT PRIMARY KEY,
    id_cliente     INT NOT NULL,
    placa          CHAR(7) NOT NULL UNIQUE,
    marca          VARCHAR(40) NOT NULL,
    modelo         VARCHAR(60) NOT NULL,
    ano_fabricacao SMALLINT,
    cor            VARCHAR(30),
    CONSTRAINT fk_veiculo_cliente FOREIGN KEY (id_cliente) REFERENCES cliente (id_cliente)
);

-- ---------- EQUIPE / MECÂNICO (1 equipe : N mecânicos) ----------
CREATE TABLE equipe (
    id_equipe   INT AUTO_INCREMENT PRIMARY KEY,
    nome_equipe VARCHAR(60) NOT NULL UNIQUE
);

CREATE TABLE mecanico (
    codigo        INT AUTO_INCREMENT PRIMARY KEY,
    nome          VARCHAR(100) NOT NULL,
    endereco      VARCHAR(200),
    especialidade VARCHAR(60) NOT NULL,
    id_equipe     INT NOT NULL,
    CONSTRAINT fk_mecanico_equipe FOREIGN KEY (id_equipe) REFERENCES equipe (id_equipe)
);

-- ---------- TABELA DE REFERÊNCIA DE MÃO DE OBRA ----------
CREATE TABLE servico (
    id_servico        INT AUTO_INCREMENT PRIMARY KEY,
    descricao         VARCHAR(120) NOT NULL UNIQUE,
    valor_mao_de_obra DECIMAL(10,2) NOT NULL,
    CONSTRAINT chk_servico_valor CHECK (valor_mao_de_obra >= 0)
);

-- ---------- PEÇAS ----------
CREATE TABLE peca (
    id_peca            INT AUTO_INCREMENT PRIMARY KEY,
    descricao          VARCHAR(120) NOT NULL,
    valor_unitario     DECIMAL(10,2) NOT NULL,
    quantidade_estoque INT NOT NULL DEFAULT 0,
    CONSTRAINT chk_peca_valor   CHECK (valor_unitario >= 0),
    CONSTRAINT chk_peca_estoque CHECK (quantidade_estoque >= 0)
);

-- ---------- ORDEM DE SERVIÇO ----------
CREATE TABLE ordem_servico (
    numero_os               INT AUTO_INCREMENT PRIMARY KEY,
    id_veiculo              INT NOT NULL,
    id_equipe               INT NOT NULL,       -- a mesma equipe avalia e executa
    tipo                    ENUM('CONSERTO','REVISAO') NOT NULL,
    data_emissao            DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    data_conclusao_prevista DATE NOT NULL,      -- data de entrega informada ao cliente
    data_conclusao_real     DATE,
    valor_total             DECIMAL(10,2) NOT NULL DEFAULT 0,
    status                  ENUM('EM_ANALISE','AGUARDANDO_AUTORIZACAO','AUTORIZADA',
                                 'EM_EXECUCAO','CONCLUIDA','ENTREGUE','CANCELADA')
                            NOT NULL DEFAULT 'EM_ANALISE',
    autorizada              BOOLEAN NOT NULL DEFAULT FALSE,
    data_autorizacao        DATETIME,
    CONSTRAINT fk_os_veiculo FOREIGN KEY (id_veiculo) REFERENCES veiculo (id_veiculo),
    CONSTRAINT fk_os_equipe  FOREIGN KEY (id_equipe)  REFERENCES equipe (id_equipe),
    CONSTRAINT chk_os_prevista CHECK (data_conclusao_prevista >= DATE(data_emissao)),
    CONSTRAINT chk_os_real     CHECK (data_conclusao_real IS NULL OR data_conclusao_real >= DATE(data_emissao)),
    -- execução, conclusão e entrega só existem com a autorização do cliente
    CONSTRAINT chk_os_autorizacao CHECK (
        autorizada = TRUE OR status IN ('EM_ANALISE','AGUARDANDO_AUTORIZACAO','CANCELADA')
    )
);

-- ---------- N:M OS x SERVIÇO (valor congelado na emissão) ----------
CREATE TABLE os_servico (
    numero_os      INT NOT NULL,
    id_servico     INT NOT NULL,
    quantidade     INT NOT NULL DEFAULT 1,
    valor_unitario DECIMAL(10,2) NOT NULL,
    PRIMARY KEY (numero_os, id_servico),
    CONSTRAINT chk_oss_qtd CHECK (quantidade > 0),
    CONSTRAINT fk_oss_os      FOREIGN KEY (numero_os)  REFERENCES ordem_servico (numero_os) ON DELETE CASCADE,
    CONSTRAINT fk_oss_servico FOREIGN KEY (id_servico) REFERENCES servico (id_servico)
);

-- ---------- N:M OS x PEÇA (valor congelado na emissão) ----------
CREATE TABLE os_peca (
    numero_os      INT NOT NULL,
    id_peca        INT NOT NULL,
    quantidade     INT NOT NULL DEFAULT 1,
    valor_unitario DECIMAL(10,2) NOT NULL,
    PRIMARY KEY (numero_os, id_peca),
    CONSTRAINT chk_osp_qtd CHECK (quantidade > 0),
    CONSTRAINT fk_osp_os   FOREIGN KEY (numero_os) REFERENCES ordem_servico (numero_os) ON DELETE CASCADE,
    CONSTRAINT fk_osp_peca FOREIGN KEY (id_peca)   REFERENCES peca (id_peca)
);

-- =====================================================
-- PERSISTÊNCIA DE DADOS PARA TESTES
-- =====================================================

INSERT INTO cliente (id_cliente, nome, cpf, telefone, email, endereco) VALUES
 (1,'Carlos Silva','11122233344','46999990001','carlos@email.com','Rua das Flores, 100 - Laranjeiras do Sul/PR'),
 (2,'Marina Costa','22233344455','46999990002','marina@email.com','Rua XV de Novembro, 250 - Curitiba/PR'),
 (3,'João Pedro Alves','33344455566','46999990003','joao@email.com','Av. Brasil, 900 - Guarapuava/PR'),
 (4,'Fernanda Rocha','44455566677','46999990004','fernanda@email.com','Rua do Comércio, 75 - Cascavel/PR'),
 (5,'Ricardo Mendes','55566677788','46999990005','ricardo@email.com','Rua das Acácias, 45 - Londrina/PR');

INSERT INTO veiculo (id_veiculo, id_cliente, placa, marca, modelo, ano_fabricacao, cor) VALUES
 (1,1,'ABC1D23','Fiat','Uno',2014,'Prata'),
 (2,1,'EFG4H56','Chevrolet','Onix',2020,'Preto'),
 (3,2,'IJK7L89','Honda','Civic',2018,'Branco'),
 (4,3,'MNO0P12','Toyota','Hilux',2016,'Cinza'),
 (5,4,'QRS3T45','Volkswagen','Gol',2012,'Vermelho'),
 (6,5,'UVW6X78','Hyundai','HB20',2022,'Azul');   -- veículo sem nenhuma OS

INSERT INTO equipe (id_equipe, nome_equipe) VALUES (1,'Equipe Alfa'), (2,'Equipe Beta'), (3,'Equipe Gama');

INSERT INTO mecanico (codigo, nome, endereco, especialidade, id_equipe) VALUES
 (101,'João Pereira','Rua A, 10','Motor',1),
 (102,'Marcos Lima','Rua B, 20','Freios e suspensão',1),
 (103,'André Souza','Rua C, 30','Elétrica',2),
 (104,'Paulo Rocha','Rua D, 40','Injeção eletrônica',2),
 (105,'Luiz Gomes','Rua E, 50','Câmbio e embreagem',3),
 (106,'Tiago Nunes','Rua F, 60','Motor',3);

INSERT INTO servico (id_servico, descricao, valor_mao_de_obra) VALUES
 (1,'Troca de óleo',80.00),
 (2,'Alinhamento',120.00),
 (3,'Balanceamento',60.00),
 (4,'Revisão de freios',150.00),
 (5,'Troca de correia dentada',350.00),
 (6,'Diagnóstico eletrônico',200.00),
 (7,'Troca de embreagem',450.00),
 (8,'Revisão completa',400.00);

INSERT INTO peca (id_peca, descricao, valor_unitario, quantidade_estoque) VALUES
 (1,'Filtro de óleo',35.00,20),
 (2,'Óleo 5W30 (litro)',45.00,60),
 (3,'Pastilha de freio (jogo)',180.00,10),
 (4,'Disco de freio (unidade)',260.00,1),
 (5,'Correia dentada',140.00,4),
 (6,'Kit de embreagem',620.00,2),
 (7,'Vela de ignição',28.00,40),
 (8,'Filtro de ar',42.00,3);

INSERT INTO ordem_servico (numero_os, id_veiculo, id_equipe, tipo, data_emissao, data_conclusao_prevista,
                           data_conclusao_real, status, autorizada, data_autorizacao) VALUES
 (1,1,1,'REVISAO' ,'2026-09-02 09:00:00','2026-09-04','2026-09-04','ENTREGUE'              ,TRUE ,'2026-09-02 10:00:00'),
 (2,3,2,'CONSERTO','2026-09-15 08:30:00','2026-09-20','2026-09-19','ENTREGUE'              ,TRUE ,'2026-09-15 11:00:00'),
 (3,4,3,'CONSERTO','2026-09-25 14:00:00','2026-10-02','2026-10-01','CONCLUIDA'             ,TRUE ,'2026-09-26 09:30:00'),
 (4,2,1,'REVISAO' ,'2026-10-05 10:15:00','2026-10-07','2026-10-08','CONCLUIDA'             ,TRUE ,'2026-10-05 11:00:00'),
 (5,5,2,'CONSERTO','2026-10-12 09:45:00','2026-10-18',NULL        ,'EM_EXECUCAO'           ,TRUE ,'2026-10-12 15:00:00'),
 (6,3,1,'REVISAO' ,'2026-10-20 13:20:00','2026-10-24',NULL        ,'AGUARDANDO_AUTORIZACAO',FALSE,NULL),
 (7,4,3,'REVISAO' ,'2026-10-22 08:00:00','2026-10-26',NULL        ,'AUTORIZADA'            ,TRUE ,'2026-10-23 10:10:00'),
 (8,1,1,'CONSERTO','2026-10-25 16:30:00','2026-10-30',NULL        ,'CANCELADA'             ,FALSE,NULL);

INSERT INTO os_servico (numero_os, id_servico, quantidade, valor_unitario) VALUES
 (1,1,1,80.00),(1,4,1,150.00),
 (2,6,1,200.00),
 (3,7,1,450.00),
 (4,1,1,80.00),(4,2,1,120.00),(4,3,1,60.00),
 (5,6,1,200.00),(5,5,1,350.00),
 (6,8,1,400.00),
 (7,1,1,80.00),(7,4,1,150.00),
 (8,6,1,200.00);

INSERT INTO os_peca (numero_os, id_peca, quantidade, valor_unitario) VALUES
 (1,1,1,35.00),(1,2,4,45.00),(1,3,1,180.00),
 (2,7,4,28.00),
 (3,6,1,620.00),
 (4,1,1,35.00),(4,2,4,45.00),(4,8,1,42.00),
 (5,5,1,140.00),
 (6,1,1,35.00),(6,2,4,45.00),(6,8,1,42.00),
 (7,3,1,180.00),(7,4,2,260.00);

-- Valor da OS = mão de obra (serviços) + peças
UPDATE ordem_servico o
SET o.valor_total =
    (SELECT COALESCE(SUM(s.quantidade * s.valor_unitario), 0) FROM os_servico s WHERE s.numero_os = o.numero_os)
  + (SELECT COALESCE(SUM(p.quantidade * p.valor_unitario), 0) FROM os_peca p WHERE p.numero_os = o.numero_os);
