create schema clinica; 
use clinica; 

create table paciente ( 
id_paciente int auto_increment primary key, 
Nome  varchar (100),
Especie varchar (50),
Idade int
 );
 
 insert into paciente (Nome, Especie, Idade)
 values ('PÉ DE PANO','CAVALO',20);
 SELECT * FROM paciente;
 
 create table veterinario (
 id_veterinario int auto_increment primary key,
 Nome varchar (100), 
 Especialidade VARCHAR (50)
 );
 
 insert into veterinario (Nome, Especialidade)
 values ('Dr Chapatin', 'Porte grande');
 SELECT * FROM veterinario;
 
 create table consultas ( 
 id_consulta int auto_increment primary key,
 id_paciente int,
 id_veterinario int,
 Data_consulta date, 
 Custo decimal (10,2),
 Foreign key (id_paciente) references paciente (id_paciente),
 Foreign key (id_veterinario)  references veterinario (id_veterinario)
 ); 
 
 insert into consultas (id_paciente, id_veterinario, Data_consulta, Custo)
 values (1,1,'2002-08-09', 10.80);
 SELECT * FROM consultas; 
  
  DELIMITER // 
  create procedure agendar_consulta(
  in p_id_paciente int,
  in p_id_veterinario int, 
  in p_Data_consulta date,
  in p_custo decimal (10,2)
  )
  begin
    insert into consultas (id_paciente, id_veterinario, Data_consulta, Custo)
    values (p_id_paciente, p_id_veterinario, p_Data_consulta, p_custo);
	end // 
	
DELIMITER ;

CALL agendar_consulta(1, 1, '2024-09-30', 100.50);


DELIMITER //
create procedure atualizar_paciente(
    in p_id_paciente int,
    in p_novo_nome varchar (100),
    in p_nova_especie varchar(50),
    in p_nova_idade int
)
begin
    update paciente
    Set Nome = p_novo_nome,
        Especie = p_nova_especie,
        Idade = p_nova_idade
    where id_paciente = p_id_paciente;
end //

DELIMITER ;
call atualizar_paciente (1,'tango','orangotango',20);


DELIMITER // 
create procedure remover_consulta(
in p_id_consulta int 
)
begin
delete from consultas 
where id_consulta = p_id_consulta;
end// 

DELIMITER ; 
CALL remover_consulta(1); 


DELIMITER //
create function total_gasto_paciente(
p_id_paciente int
)
returns decimal(10,2)
deterministic 
begin 
declare total decimal(10,2);

SELECT COALESCE(SUM(Custo),0) into total
from consultas
where id_paciente = p_id_paciente; 

if total is null then 
set total = 0.00;
end if; 

return total; 
END// 

DELIMITER ;
SELECT total_gasto_paciente(1) AS total_gasto;



DELIMITER //
create trigger verificar_idade_paciente
before insert on paciente
for each row
begin 
    IF NEW.Idade <= 0 THEN
        SIGNAL SQLSTATE '100'
        SET MESSAGE_TEXT = 'iDADE INVALIDA.';
    END IF;
end //

DELIMITER ;

insert into paciente (Nome, Especie, Idade) 
VALUES ('CHORRO', 'CACHORRO', -6);



DELIMITER // 
create trigger atualizar_custo_consulta
after update on consultas
for each row
begin 
    IF OLD.Custo <> NEW.Custo THEN
       insert into Log_Consultas (id_consulta, custo_antigo, custo_novo)
        values (NEW.id_consulta, OLD.Custo, NEW.Custo);
    END IF;
End //

DELIMITER ;
UPDATE consultas SET Custo = 50.00 WHERE id_consulta = 1;

/*
Atividade 2 Clinica veterinaria (Continuação)
*/


create table tratamento (
    id_tratamento int AUTO_INCREMENT PRIMARY KEY,
    id_paciente int,
    Descricao varchar (400),
    Data_tratamento date,
    FOREIGN KEY (id_paciente) REFERENCES paciente(id_paciente)
);
insert into tutor (id_paciente, descricao, Data_tratamento)
values (1, 'carrapato', '2024-09-20,');


create table medicamento (
    id_medicamento int auto_increment primary key,
    Nome varchar(100),
    quantidade varchar (50),
    Preco decimal (10, 2)
    );
insert into medicamento (Nome, quantidade, preco)
values ('dorflex','1 comprimido', 10.20);

create table receituario (
    id_receituario int auto_increment primary key,
    id_tratamento int,
    id_medicamento int,
    Dosagem varchar (50),
    FOREIGN KEY (id_tratamento) REFERENCES tratamento(id_tratamento),
    FOREIGN KEY (id_medicamento) REFERENCES medicamento(id_medicamento)
);

DELIMITER //
CREATE TRIGGER set_data_tratamento
BEFORE INSERT ON tratamento
FOR EACH ROW
BEGIN
    SET NEW.Data_tratamento = CURDATE();
END //
DELIMITER ;


DELIMITER //
CREATE TRIGGER medicamento_preco
BEFORE INSERT ON medicamento
FOR EACH ROW
BEGIN
    IF NEW.Preco <= 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Preço do medicamento inválido.';
    END IF;
END //
DELIMITER ;



DELIMITER //
CREATE TRIGGER log_tratamento
AFTER INSERT ON tratamento
FOR EACH ROW
BEGIN
    INSERT INTO Log_Tratamentos (id_tratamento, descricao)
    VALUES (NEW.id_tratamento, NEW.Descricao);
END //
DELIMITER ;



DELIMITER //
CREATE TRIGGER verificar_idade_update
BEFORE UPDATE ON paciente
FOR EACH ROW
BEGIN
    IF NEW.Idade < 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Idade não pode ser menos que 0.';
    END IF;
END //
DELIMITER ;



DELIMITER //
CREATE TRIGGER prevent_duplicate_medicamento
BEFORE INSERT ON medicamento
FOR EACH ROW
BEGIN
    IF EXISTS (SELECT 1 FROM medicamento WHERE Nome = NEW.Nome) THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Medicamento já existe.';
    END IF;
END 
DELIMITER ;


DELIMITER //
CREATE PROCEDURE adicionar_tratamento(
    IN p_id_paciente INT,
    IN p_descricao VARCHAR(255)
)
BEGIN
    INSERT INTO tratamento (id_paciente, Descricao)
    VALUES (p_id_paciente, p_descricao);
END //
DELIMITER ;

CALL adicionar_tratamento(1, 'Tratamento de carrapato manco');



DELIMITER //
CREATE PROCEDURE adicionar_medicamento(
    IN p_nome VARCHAR(100),
    IN p_dosagem VARCHAR(50),
    IN p_preco DECIMAL(10, 2)
)
BEGIN
    INSERT INTO medicamento (Nome, Dosagem, Preco)
    VALUES (p_nome, p_dosagem, p_preco);
END //
DELIMITER ;

CALL adicionar_medicamento('dorflex na veia', '500mg', 15.00);



DELIMITER //
CREATE PROCEDURE adicionar_prescricao(
    IN p_id_tratamento INT,
    IN p_id_medicamento INT,
    IN p_dosagem VARCHAR(50)
)
BEGIN
    INSERT INTO receituario (id_tratamento, id_medicamento, Dosagem)
    VALUES (p_id_tratamento, p_id_medicamento, p_dosagem);
END //
DELIMITER ;

CALL adicionar_receituario (1, 1, '2 vezes ao dia');


DELIMITER //
CREATE PROCEDURE listar_tratamentos(
    IN p_id_paciente INT
)
BEGIN
    SELECT * FROM tratamento WHERE id_paciente = p_id_paciente;
END //
DELIMITER ;

CALL listar_tratamentos(1);



DELIMITER //
CREATE PROCEDURE atualizar_preco_medicamento(
    IN p_id_medicamento INT,
    IN p_novo_preco DECIMAL(10, 2)
)
BEGIN
    UPDATE medicamento SET Preco = p_novo_preco
    WHERE id_medicamento = p_id_medicamento;
END //
DELIMITER ;


CALL atualizar_preco_medicamento(1, 20.00);