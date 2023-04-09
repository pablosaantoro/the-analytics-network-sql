CLASE 1
--1. Mostrar todos los productos dentro de la categoria electro junto con todos los detalles.
select * from stg.product_master
where categoria = 'Electro'

--2. ¿Cuáles son los productos producidos en China?
select nombre from stg.product_master
where origen = 'China'

--3. Mostrar todos los productos de Electro ordenados por nombre.
select * from stg.product_master
where categoria = 'Electro'
order by nombre asc  

--4. Cuales son las TV que se encuentran activas para la venta?
select nombre from stg.product_master
where subcategoria = 'TV' and is_active = 'true'

--5. Mostrar todas las tiendas de Argentina ordenadas por fecha de apertura de las mas antigua a la mas nueva.
select nombre, fecha_apertura from stg.store_master
where pais = 'Argentina'
order by fecha_apertura asc

--6. Cuales fueron las ultimas 5 ordenes de ventas?
select * from stg.order_line_sale
order by fecha DESC
limit 5

--7. Mostrar los primeros 10 registros del conteo de tráfico por Super store ordenados por fecha.
select * from stg.super_store_count
order by fecha ASC
limit 10

--8. Cuales son los productos de electro que no son Soporte de TV ni control remoto.
select nombre from stg.product_master
where categoria = 'Electro' and subsubcategoria not in ('Soporte','Control remoto')
order by nombre asc
--where categoria = 'Electro' and subsubcategoria != 'Soporte' and subsubcategoria != 'Control remoto'

--9. Mostrar todas las lineas de venta donde el monto sea mayor a $100.000 solo para transacciones en pesos.
select * from stg.order_line_sale
where moneda = 'ARS' and venta > 100000
order by venta desc

--10. Mostrar todas las lineas de ventas de Octubre 2022.
select * from stg.order_line_sale
where fecha between '2022-10-01' and '2022-10-31'
order by fecha asc

--11. Mostrar todos los productos que tienen EAN.
select * from stg.product_master
where ean is not null
order by nombre asc

--12. Mostrar todas las lineas de venta que han sido vendidas entre 1 de Octubre de 2022 y 10 de Noviembre de 2022./
select * from stg.order_line_sale
where fecha between '2022-10-01' and '2022-11-10'
order by fecha asc

CLASE 2
--1. Cuales son los paises donde la empresa tiene tiendas?
select distinct pais from stg.store_master
order by pais asc

--2. ¿Cuántos productos por subcategoría tiene disponible para la venta?
select subcategoria,
       count(nombre) as qty
from stg.product_master
group by subcategoria
order by qty desc

--3. Cuales son las ordenes de venta de Argentina de mayor a $100.000?
select orden from stg.order_line_sale
where venta > 100000 and moneda = 'ARS'
order by orden asc

--4. Obtener los descuentos otorgados durante Noviembre de 2022 en cada una de las monedas?
select moneda,
       sum(descuento) as descuentos_otorgados
from stg.order_line_sale
where fecha between '2022-11-01' and '2022-11-30'
group by moneda

--5. Obtenga los impuestos pagados en Europa durante el 2022.
select sum(impuestos) as impuestos_pagados
from stg.order_line_sale
where moneda = 'EUR' and fecha between '2022-01-01' and '2022-12-31'

--6. ¿En qué órdenes se utilizaron créditos?
select distinct orden from stg.order_line_sale
where creditos is not null
order by orden asc

--7. ¿Cuál es el % de descuentos otorgados (sobre las ventas) por tienda?
select tienda,
       concat(round(((sum(descuento)/sum(venta))*-100),2),'%') as descuentos_otorgados
from stg.order_line_sale
group by tienda
order by tienda

--8. ¿Cuál es el inventario promedio por día que tiene cada tienda?
select tienda,
	fecha,
	round(avg(inicial + final),2) as inventario_promedio
from stg.inventory
group by tienda, fecha
order by tienda, fecha

--9. Obtener las ventas netas y el porcentaje de descuento por producto en Argentina.
select producto,
	round(sum(venta) + sum(coalesce(descuento, 0)) - sum(impuestos) + sum(coalesce(creditos, 0)),2) as ventas_netas,
	round(sum(coalesce(descuento, 0))/sum(venta),2)*100 as porcentaje_descuento
from stg.order_line_sale
where moneda = 'ARS'
group by producto
order by producto

--10. Las tablas "market_count" y "super_store_count" representan dos sistemas distintos que usa la empresa para contar la cantidad de personas que ingresa a una tienda, una para las tiendas de Latinoamerica y otra para Europa. Obtener en una unica tabla, las entradas a tienda de ambos sistemas.
select tienda, date(cast(fecha as text)),conteo from stg.market_count
union all
select tienda, date(cast(fecha as text)), conteo from stg.super_store_count

--11. Cuales son los productos disponibles para la venta (activos) de la marca Phillips?
select * from stg.product_master
where is_active = 'true' and nombre like '%PHILIPS%'

--12. Obtener el monto vendido por tienda y moneda y ordenarlo de mayor a menor por valor nominal.
select
    tienda,
    round(sum(venta) + sum(coalesce(descuento, 0)),2) as valor_nominal,
    moneda
from
    stg.order_line_sale
group by
    tienda,
    moneda
order by
    valor_nominal desc

--13. ¿Cuál es el precio promedio de venta de cada producto en las distintas monedas? Recorda que los valores de venta, impuestos, descuentos y creditos es por el total de la linea.
select producto,
	round(sum(venta)/sum(cantidad),2) as precio_promedio,
moneda
from stg.order_line_sale
group by producto, moneda
order by producto, moneda

--14. ¿Cuál es la tasa de impuestos que se paga por cada orden de venta?
select orden,
	round(sum(impuestos)/sum(venta),2) as tasa_impuestos,
	moneda
from stg.order_line_sale
group by orden, moneda
order by orden

CLASE 3
--1. Mostrar nombre y codigo de producto, categoria y color para todos los productos de la marca Philips y Samsung, mostrando la leyenda "Unknown" cuando no hay un color disponible
with color_correcto as (
select *, 
	case
	when color is null then 'Unknown'
	else color
	end as color_nuevo 
from stg.product_master
)

select nombre, codigo_producto, categoria, color_nuevo
from color_correcto
where nombre like '%PHILIPS%' or nombre like '%SAMSUNG%'

--2. Calcular las ventas brutas y los impuestos pagados por pais y provincia en la moneda correspondiente.
select ols.tienda,
	sum(ols.venta) as ventas_brutas,
	sum(ols.impuestos) as impuestos_pagados,
	ols.moneda,
	sm.pais,
	sm.provincia
from stg.order_line_sale as ols
left join stg.store_master as sm
on ols.tienda = sm.codigo_tienda
group by ols.tienda, ols.moneda, sm.pais, sm.provincia
order by ols.tienda

--3. Calcular las ventas totales por subcategoría de producto para cada moneda ordenada por subcategoría y moneda.
select sum(ols.venta),
	ols.moneda,
	pm.subcategoria
from stg.order_line_sale as ols
left join stg.product_master as pm
on ols.producto = pm.codigo_producto
group by ols.moneda, pm.subcategoria
order by pm.subcategoria, ols.moneda

--4. Calcular las unidades vendidas por subcategoria de producto y la concatenacion de pais, provincia; usar guion como separador y usarla para ordernar el resultado.
with pais_provincia as (
select sm.codigo_tienda,
	concat(sm.pais, ' - ', sm.provincia) as origen
from stg.store_master sm
)

select pp.origen,
	sum(ols.cantidad),
	pm.subcategoria
from stg.order_line_sale as ols
left join stg.product_master as pm
on ols.producto = pm.codigo_producto
left join pais_provincia as pp
on ols.tienda = pp.codigo_tienda
group by pm.subcategoria, pp.origen
order by pp.origen

--5. Mostrar una vista donde sea vea el nombre de tienda y la cantidad de entradas de personas que hubo desde la fecha de apertura para el sistema "super_store".
select sm.nombre,
	sum(ssc.conteo) as cantidad_entradas
from stg.super_store_count as ssc
left join stg.store_master as sm
on ssc.tienda = sm.codigo_tienda
group by sm.nombre

--6. Cual es el nivel de inventario promedio en cada mes a nivel de codigo de producto y tienda; mostrar el resultado con el nombre de la tienda.
with obtener_mes as (
select *, date(date_trunc('month',i.fecha)) as mes
from stg.inventory as i
)

select om.tienda,
	sm.nombre,
	om.sku,
	sum(om.inicial+om.final)/2 as inventario_promedio,
	om.mes	
from obtener_mes as om
left join stg.store_master as sm
on om.tienda = sm.codigo_tienda
group by om.tienda, sm.nombre, om.sku, om.mes

--7. Calcular la cantidad de unidades vendidas por material. Para los productos que no tengan material usando 'Unknown', homogeneizar los textos si es necesario.
with material_corregido as (
select *,
	case
	when material is null then 'Unknown'
	when material = 'plastico' then 'Plastico'
	when material = 'PLASTICO' then 'Plastico'
	else material
	end as material_homogeneizado 
from stg.product_master
)

select mc.material_homogeneizado,
	sum(ols.cantidad) as unidades_vendidas
from stg.order_line_sale as ols
left join material_corregido as mc
on ols.producto = mc.codigo_producto
group by mc.material_homogeneizado
order by unidades_vendidas desc

--8. Mostrar la tabla order_line_sales agregando una columna que represente el valor de venta bruta en cada línea convertida a dólares usando la tabla de tipo de cambio.
select ols.*,
	case
	when moneda = 'ARS' then ols.venta / fx.cotizacion_usd_peso
	when moneda = 'URU' then ols.venta / fx.cotizacion_usd_uru
	when moneda = 'EUR' then ols.venta / fx.cotizacion_usd_eur
	end as venta_bruta_usd
from stg.order_line_sale as ols
left join stg.monthly_average_fx_rate as fx
on date(date_trunc('month', ols.fecha)) = fx.mes

--9. Calcular cantidad de ventas totales de la empresa en dolares.
with ventas_usd as (
select ols.*,
	case
	when moneda = 'ARS' then ols.venta / fx.cotizacion_usd_peso
	when moneda = 'URU' then ols.venta / fx.cotizacion_usd_uru
	when moneda = 'EUR' then ols.venta / fx.cotizacion_usd_eur
	end as venta_bruta_usd
from stg.order_line_sale as ols
left join stg.monthly_average_fx_rate as fx
on date(date_trunc('month', ols.fecha)) = fx.mes
)

select sum(venta_bruta_usd) from ventas_usd

--10. Mostrar en la tabla de ventas el margen de venta por cada linea. Siendo margen = (venta - descuento) - costo expresado en dolares.
select ols.*,
	case
	when moneda = 'ARS' then ((ols.venta - coalesce(ols.descuento,0)) / fx.cotizacion_usd_peso) - c.costo_promedio_usd
	when moneda = 'URU' then ((ols.venta - coalesce(ols.descuento,0)) / fx.cotizacion_usd_uru) - c.costo_promedio_usd
	when moneda = 'EUR' then ((ols.venta - coalesce(ols.descuento,0)) / fx.cotizacion_usd_eur) - c.costo_promedio_usd
	end as margen
from stg.order_line_sale as ols
left join stg.monthly_average_fx_rate as fx
on date(date_trunc('month', ols.fecha)) = fx.mes
left join stg.cost as c
on ols.producto = c.codigo_producto

--11. Calcular la cantidad de artículos distintos de cada subsubcategoría que se llevan por número de orden.
select ols.orden,
	pm.subcategoria,
	count(distinct producto)
from stg.order_line_sale as ols
left join stg.product_master as pm
on ols.producto = pm.codigo_producto
group by ols.orden, pm.subcategoria

CLASE 4
--1. Cree una copia de seguridad de la tabla product_master. Usar un esquema de llamada "bkp" y agregar un prefijo al nombre de la tabla con la fecha del respaldo en forma de número entero.
create schema bkp;
select *
into bkp.product_master_20220409
from stg.product_master

--2. Hacer un update a la nueva tabla (creada en el punto anterior) de product_master agregando la lectura "N/A" para los valores null de material y color. Pueden convertirse en dos sentencias.
update bkp.product_master_20220409 set material = 'N/A' where material is null
update bkp.product_master_20220409 set color = 'N/A' where color is null

--3. Hacer un update a la tabla del punto anterior, actualizando la columa "is_active", desactivando todos los productos en la subsubcategoria "Control Remoto".
update bkp.product_master_20220409 set is_active = false where subsubcategoria = 'Control remoto'

--4. Agregar una nueva columna a la tabla anterior "is_local" indicando los productos producidos en Argentina y fuera de Argentina.
alter table bkp.product_master_20220409 
add column is_local boolean;

update bkp.product_master_20220409 set is_local = case when origen = 'Argentina' then true else false end

--5. Agregar una nueva columna a la tabla de ventas llamada "line_key" que resulte ser la concatenación del número de orden y el código de producto.
select *
into bkp.order_line_sale_20220409
from stg.order_line_sale

alter table bkp.order_line_sale_20220409
add column line_key varchar(255);

update bkp.order_line_sale_20220409 set line_key = concat(orden, ' - ', producto)

--6. Eliminar todos los valores de la tabla "order_line_sale" para el POS 1.
delete from bkp.order_line_sale_20220409 where pos = 1

--7. Crear una tabla llamada "employees" (por el momento vacia) que tenga un id (creado de forma incremental), nombre, apellido, fecha de entrada, fecha de salida, telefono, pais, provincia, codigo_tienda, posicion. Decidir cual es el tipo de dato mas acorde.
create table bkp.employees (
                        id serial primary key,
                        nombre VARCHAR (255),
                        apellido VARCHAR (255),
                        fecha_entrada DATE,
                        fecha_salida DATE,
                        telefono BIGINT,
                        pais VARCHAR (255),
                        provincia VARCHAR (255),
                        codigo_tienda INTEGER,
                        posicion VARCHAR (255))

--8. Insertar nuevos valores a la tabla "empleados" para los siguientes 4 empleados:
-- Juan Pérez, 2022-01-01, teléfono +541113869867, Argentina, Santa Fe, tienda 2, Vendedor.
-- Catalina García, 2022-03-01, Argentina, Buenos Aires, tienda 2, Representante Comercial
-- Ana Valdez, desde 2020-02-21 hasta 2020-02-21, España, Madrid, tienda 8, Jefe Logistica
-- Fernando Moralez, 2022-04-04, España, Valencia, tienda 9, Vendedor.
insert into bkp.employees(nombre, apellido, fecha_entrada, telefono, pais, provincia, codigo_tienda, posicion)  values ('Juan', 'Pérez', '20220101', 541113869867, 'Argentina', 'Santa Fe', 2, 'Vendedor')
insert into bkp.employees(nombre, apellido, fecha_entrada, pais, provincia, codigo_tienda, posicion)  values ('Catalina', 'García', '20220301', 'Argentina', 'Buenos Aires', 2, 'Representante Comercial')
insert into bkp.employees(nombre, apellido, fecha_entrada, fecha_salida, pais, provincia, codigo_tienda, posicion)  values ('Ana', 'Valdez', '20200221', '20200221',  'España', 'Madrid', 8, 'Jefe Logistica')
insert into bkp.employees(nombre, apellido, fecha_entrada, pais, provincia, codigo_tienda, posicion)  values ('Fernando', 'Moralez', '20220404', 'España', 'Valencia', 9, 'Vendedor')

--9. Cree una copia de seguridad de la tabla "cost" agregandole una columna que se llame "last_updated_ts" que sea el momento exacto en el cual estemos realizando la copia de seguridad en formato datetime.
select *,
	date(now()) as last_update_ts
into bkp.cost_20230409
from stg.cost

--10. El cambio en la tabla "order_line_sale" en el punto 6 fue un error y debemos volver la tabla a su estado original, como lo harias?













