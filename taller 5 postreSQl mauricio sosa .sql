
--1.  Crear una nueva cuenta bancaria
create or replace procedure crear_cuenta_bancaria (
	id_cliente integer, 
	tipo_cuenta varchar(10),
	saldo_inicial numeric(15, 2))
language plpgsql
as $$
 
	declare numero_cuenta_bus varchar(20);
	declare existe_dato boolean;
	
 
    begin
	
	   if id_cliente = 0  then 
	       raise exception 'Debe ingresar el cliente';
       end if;
	
	
	   select case when count(1) > 0 then '1' else '0' end into existe_dato
       from clientes  where cliente_id = id_cliente ;
	   if not existe_dato then 
	      raise exception 'El cliente no esta registrado';
	   end if;
		
       existe_dato = 1;
	   while existe_dato = '1' loop
	    numero_cuenta_bus = substr(cast(random() as text), 1, 20);
        select case when count(1) > 0 then '1' else '0' end into existe_dato
          from cuenta_bancaria  where numero_cuenta = numero_cuenta_bus; 
       end loop;
	
  
	   insert into cuenta_bancaria(cliente_id, numero_cuenta, tipo_cuenta, saldo, 
									 fecha_apertura, estado)
	   values(id_cliente, numero_cuenta_bus, tipo_cuenta, saldo_inicial,
				current_timestamp, 'ACTIVA');
    end;
$$; 


--2.  Actualizar la información del cliente

create or replace procedure actualizar_cliente (
	id_cliente integer, 
	direccion_new varchar(100),
	telefono_new varchar(20),
    email_new varchar(100))
language plpgsql
as $$
    -- creacion de variables
	declare existe_dato boolean;
	

    begin
	-- se valida cliente
	   if id_cliente = 0  then 
	       raise exception 'Debe ingresar el cliente';
       end if;
			
	   select case when count(1) > 0 then '1' else '0' end into existe_dato
       from clientes  where cliente_id = id_cliente ;
	   if not existe_dato then 
	      RAISE EXCEPTION 'El cliente no existe';
	   end if;
  
	   if direccion_new <> ' ' then 
	      update  clientes set direccion = direccion_new 	                        
	     where cliente_id = id_cliente;
       end if;
	   if telefono_new <> ' '  then 
	       update  clientes set telefono = telefono_new
	       where cliente_id = id_cliente;
	   end if;
	   if email_new <> ' ' then 
	       update  clientes set  correo_electronico = email_new							
	       where cliente_id = id_cliente;
       end if;
		
    end;
$$;


--3.Eliminar una cuenta bancaria

create or replace procedure eliminar_cuenta_bancaria (
	id_cuenta integer)
language plpgsql
as $$
    
	declare existe_dato boolean;

    begin
	-- se valida cliente
	   if id_cuenta = 0  then 
	       raise exception 'debe ingresar el id de cuenta a eliminar';
       end if;
	   
	   select case when count(1) > 0 then '1' else '0' end into existe_dato
	    from cuenta_bancaria 
	   where cuenta_id = id_cuenta;
	   
	   if not existe_dato  then 
	       raise exception 'Cuenta bancaria no existe';
       end if;
	   
    
	   delete  from transacciones 
	   where cuenta_id = id_cuenta;
	   
	   delete  from prestamos 
	   where cuenta_id = id_cuenta;
	   
	   delete  from tarjeta_credito 
	   where cuenta_id = id_cuenta;
	   
	   delete  from cuenta_bancaria 
	   where cuenta_id = id_cuenta;
    end;
$$;

call eliminar_cuenta_bancaria(1);

--4.Transferir fondos entre cuentas
create or replace procedure tranferir_saldo_cuentas (
	id_cuenta_origen integer, 
	id_cuenta_destino integer,
	valor_transferencia numeric(15, 2),
    concepto varchar(100))
language plpgsql
as $$
    -- creacion de variables
	declare existe_dato boolean;
 
    begin
	-- se valida cuentas
	   if id_cuenta_origen = 0  then 
	       raise exception 'Debe ingresar id de cuenta origen';
       end if;
	   
	   if id_cuenta_destino = 0  then 
	       raise exception 'Debe ingresar id de cuenta destino';
       end if;
	   
	   if valor_transferencia <= 0 then
	      raise exception 'Valor a trasnferir en cero o negativo';
	   end if;
	
       select case when count(1) > 0 then '1' else '0' end into existe_dato
         from cuentas_bancarias  where cuenta_id = id_cuenta_origen; 
		 
	   if not existe_cuenta  then
	      raise exception 'Cuenta origen no existe';
	   end if;
	   
	   select case when count(1) > 0 then '1' else '0' end into existe_dato
         from cuentas_bancarias  where cuenta_id = id_cuenta_destino; 
		 
	   if not existe_cuenta  then
	      raise exception 'Cuenta destino no existe';
	   end if;
	
    
	   insert into transacciones(cuenta_id, tipo_transaccion, monto, fecha_transaccion, descripcion) 
	   values(id_cuenta_origen, 'RETIRO', valor_transferencia, current_timestamp, concepto);
	   
	   insert into transacciones(cuenta_id, tipo_transaccion, monto, fecha_transaccion, descripcion) 
	   values(id_cuenta_destino, 'ABONO', valor_transferencia, current_timestamp, concepto);
	   
	   update cuenta_bancaria set saldo = saldo - valor_transferencia where cuenta_id = id_cuenta_origen; 
	   update cuenta_bancaria set saldo = saldo + valor_transferencia where cuenta_id = id_cuenta_destino; 
    end;
$$;

--5.  Agregar una nueva transacción

create or replace procedure registrar_transaccion(
	id_cuenta integer, 
	valor_transferencia numeric(15, 2),
	tipo_transaccion_new varchar(13),
    concepto varchar(100))
language plpgsql
as $$
    -- creacion de variables
	declare existe_dato boolean;
 
    begin
	-- se valida cuentas
	   if id_cuenta = 0  then 
	       raise exception 'Debe ingresar id de cuenta';
       end if;
	   
	   if valor_transferencia <= 0 then
	      raise exception 'Valor a trasnferir en cero o negativo';
	   end if;
	
       select case when count(1) > 0 then '1' else '0' end into existe_dato
         from cuenta_bancaria  where cuenta_id = id_cuenta; 
		 
	   if not existe_dato  then
	      raise exception 'Cuenta no existe';
	   end if;
	   
	   if tipo_transaccion_new not in('Depósito', 'Retiro') then
	   	      raise exception 'tipo transacción no existe';
	   end if;
	 
	   insert into transacciones(cuenta_id, tipo_transaccion, monto, fecha_transaccion, descripcion) 
	   values(id_cuenta, tipo_transaccion_new, valor_transferencia, current_timestamp, concepto);
	   
	   if tipo_transaccion_new  = 'Retiro' then
	   update cuentas_bancarias set saldo = saldo - valor_transferencia where cuenta_id = id_cuenta;  
       else
	   update cuenta_bancaria set saldo = saldo + valor_transferencia where cuenta_id = id_cuenta;  
	   end if;
	end;
$$;

--6.  Calcular el saldo total de todas las cuentas de un cliente

create or replace function calcular_saldo_cliente (id_cliente integer)
returns numeric(15,2)
language plpgsql
as $$
    -- creacion de variables
    declare saldo_cliente numeric(15, 2) default 0.00;
	
    begin
	--
       select sum(saldo)
	   into saldo_cliente
       from cuenta_bancaria 
	   where cliente_id = id_cliente and estado = 'ACTIVA';

    -- retorno 
       return saldo_cliente;
    end;
$$; 


--7.  Generar un reporte de transacciones para un rango de fechas

create or replace function reporte_transacciones (fecha_inicial timestamp, fecha_final timestamp)
returns table(transaccion_id_bus integer,
			 cuenta_id_bus integer,
			 tipo_transaccion_bus varchar,
			 monto_bus  numeric,
			 fecha_transaccion_bus timestamp,
			 descripcion_bus  varchar) 
 language plpgsql
 as $$
 
    begin
    -- logica de la funcion
	   return query
       select *
       from transacciones 
	   where fecha_transaccion between fecha_inicial and fecha_final;
    end;
$$; 
