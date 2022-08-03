#---------------------------------------------------------------------------------------
# CARGAR LIBRERÍAS
#---------------------------------------------------------------------------------------

## Librería
library("tidyverse")
library("data.table") # Manipular bases
#library("assertive") # Corroborar clases de variables
#library("visdat") # Visualizar dataset para corroborar errores 
#library("stringdist") # Calcular distancia en strings
#library("fuzzyjoin") # Realizar merge de strings 
#library("reclin") # Comparar strings en dos datasets 
#library("skimr") # Resumen estadístico de variables (similar a glimpse)
#library("janitor") # Limpiar el nombre de las variables en la base
#library("moderndive") # Trabajar con inferencia estadística (regresiones)

library("inegiR") # INEGI
library("siebanxicor") # Banxico
library("OECD") # OECD
library("WDI") # World Bank: World Development Indicators

library("readxl") # Leer Excel 1 (en desarrollo)
library("XLConnect") # Leer Excel 2 (interfaz para leer Excel en R)
library("writexl") # Exportar archivos Excel
library("gdata") # Leer Excel 3

library("lubridate") # Manipular fechas
library("zoo") # Manipular datos

library("ggthemes") # Formato de gráficas
library("leaflet") # Gráfica de mapas interactivos
#library("leafle.extras") # Funcionalidades extras de leaflet
library("ggmap") # Visializaciones espaciales con ggplot2
library("htmltools") # Herramientas HTML
library("maps") # Visualizar mapas
library("mapproj") # Proyecciones de mapas
library("mapdata") # Bases de datos en mapas
#library("mxmaps") # Base de mapa de México

#library("httr") # Trabajar con HTML
#library("DBI") # Trabajar bases en SQL
#library("jsonlite") # Trabajar APIs en formato JSON
#library("haven") # Trabajar con datos de SAS, STATA SPSS
#library("foreign") # Trabajar con datos de SAS, STATA SPSS

#---------------------------------------------------------------------------------------
# LIMPIAR ENTORNO, DEFINIR TOKEN Y RANGO DE FECHA
#---------------------------------------------------------------------------------------

# Limpiar entorno
rm(list = ls())

#---------------------------------------------------------------------------------------
# DATOS SE: ANUNCIOS DE INVERSIÓN
#---------------------------------------------------------------------------------------

wb_se <- "/Users/antoniogarcia/Desktop/R/5. inversión/1. Datos/3. anuncios.xlsx" # Ruta Toño
anuncios_orig <- read_excel(wb_se, sheet = "Hoja1", col_names = T, range = "A9:S10000") %>% drop_na(`Empresa general`)
anuncios <- anuncios_orig %>% transmute(fecha = ymd(`Fecha de nota`), empresa = `Empresa general`, pais = `País de Origen`, inversion = `Inversión***`, 
                                     proyecto = `Proyecto`, area = `Área de negocio`, estado = Estado)

anuncios_fecha_na <- anuncios %>% filter(is.na(fecha))
anuncios_empresa_na <- anuncios %>% filter(is.na(empresa))
anuncios_pais_na <- anuncios %>% filter(is.na(pais))
anuncios_inversion_na <- anuncios %>% filter(is.na(inversion))
anuncios_proyecto_na <- anuncios %>% filter(is.na(proyecto))
anuncios_area_na <- anuncios %>% filter(is.na(area))
anuncios_estado_na <- anuncios %>% filter(is.na(estado))


anuncios_na <- tibble(
  fecha = length(anuncios_fecha_na$fecha),
  empresa = length(anuncios_empresa_na$fecha),
  pais = length(anuncios_pais_na$fecha),
  inversion = length(anuncios_inversion_na$fecha),
  proyecto = length(anuncios_proyecto_na$fecha),
  area = length(anuncios_area_na$fecha),
  estado = length(anuncios_estado_na$fecha),
)


#---------------------------------------------------------------------------------------
# DATOS SE: ANUNCIOS DE INVERSIÓN POSTERIOR AL T-MEC | LIMPIAR BASE
#---------------------------------------------------------------------------------------


# Base de trabajo 
anuncios <- anuncios %>% replace_na(list(pais = "No definido", inversion = 0L, proyecto = "No definido", area = "No definido", estado = "No definido")) %>% 
  filter(fecha >= "2020-07-01") # Inicios TMEC

# 1) Eliminar asteriscos y line breaks
anuncios <- anuncios %>% 
  mutate(pais = str_replace_all(pais, fixed("*"), ""), pais = str_replace_all(pais, "[\r\n]", ""),
         empresa = str_replace_all(empresa, fixed("*"), ""), empresa = str_replace_all(empresa, "[\r\n]", ""),
         estado = str_replace_all(estado, fixed("*"), ""), estado = str_replace_all(estado, "[\r\n]", ""),)


# 2) Limpiar Columnas País, Estado y Empresa
anuncios <- anuncios %>% 
  mutate(
    pais = str_replace_all(pais, c(
      "Corea República de" = "Corea del Sur",
      "Estados Unidos de América" = "Estados Unidos",
      "China República Popular de" = "China",
      "República Popular de China" = "China",
      "Reino Unido de Gran Bretaña e Irlanda del Norte" = "Reino Unido",
      "México/ Colombia" = "Colombia",
      "\\s*Reino Unido España México" = "Reino Unido",
      "Países BajosReino Unido" = "Reino Unido",
      "\\s*China\\s*Alemania" = "Alemania",
      "\\s*EspañaMéxico" = "España",
      "EUAMéxicoMéxicoEUA" = "Estados Unidos",
      "Estados Unidos / Austria" = "Estados Unidos",
      "México- CanadáArgentina" = "Canadá")), pais = str_trim(pais),
    estado = str_replace_all(estado, c(
      "JaliscoNacional" = "Jalisco",
      "NacionalHidalgo" = "Hidalgo",
      "Estado de MéxicoNacional" = "Estado de México",
      "QuerétaroMonterrey" = "Nuevo León",
      "VeracruzHidalgoPuebla" = "Hidalgo",
      "Baja CaliforniaSonora" = "Baja California",
      "Ciudad de MéxicoEstado de MéxicoNuevo LeónQuintana Roo" = "Ciudad de México",
      "Ciudad de MéxicoMorelosEstado de México" = "Ciudad de México",
      "Estado de México, Baja California, Jalisco y Quintana Roo." = "Estado de México",
      "GuerreroHidalgoMichoacánMorelosNayaritOaxacaPueblaTlaxcala Veracruz" = "Nacional",
      "JaliscoGuanajuato Querétaro San Luis Potosí Michoacán Colima Aguascalientes Zacatecas" = "Nacional",
      "JaliscoNuevo LeónEstado de México" = "Nacional",
      "NayaritBaja California Sur" = "Baja California Sur",
      "Nuevo LeónQuerétaroJalisco" = "Nuevo León",
      "Nuevo LeónSan Luis Potosí" = "Nuevo León",
      "Nuevo León, Puebla" = "No definido",
      "San Luis PotosíAguascalientes" = "San Luis Potosí",
      "San Luis PotosíChihuahua" = "No definido",
      "Baja California TamaulipasCiudad de México" = "No definido",
      "Veracruz y Tamaulipas" = "Veracruz")), estado = str_trim(estado),
    empresa = str_replace_all(empresa, c(
      "Bayan TreeGrupo UBK" = "Bayan Tree",
      "Lightspeed Venture PartnersAccelALLVPMantis Venture Capital" = "Lightspeed",
      "Socal Jet ServicesCaxxor Group" = "SoCal Jet Services",
      "OHLACaxxor Group" = "Caxxor Group",
      "APTIV , DELPHI Corporation" = "Delphi Corporation",
      "Siemens Energy" = "Siemens",
      "Softbank" = "SoftBank",
      "Kholer" = "Kohler",
      "Martinrea International Inc" = "Mantinrea",
      "WalMart" = "Walmart",
      "Wintershall DEA" = "Wintershall Dea",
      "WOOBOTECH" = "Woobotech",
      "(ZF Group) BCS Automotive Interface" = "BCS Automotive Interface")), empresa = str_trim(empresa),
    area = str_trim(area)
    )


# 3) Crear Columna Sector
anuncios <- anuncios %>% 
  mutate(sector = fct_collapse(area,
    `Automotriz` = c("Automotriz", "Fabricación de autopartes", "Autopartes", "Proveedor de resinas y materiales industriales", "Fabricación de autos", "Venta de automóviles", "Automotriz- equipo de transporte",  "Neumáticos", "Fabricación de Autopartes", "Fabricación de baterías para movilidad eléctrica", "Fabricación de motores", "Proveedor de sistemas y componentes automotrices", "Producción de vehículos eléctricos", "Fabricación de vehículos", "Fabricación de interiores de vehículos", "Fabricación de toldos eléctricos automotrices.", "Interiores de automóviles", "Vehículos eléctricos", "Fabricación de neumáticos", "Equipos de aire acondicionado para autos", "Automotriz- Tractocamiones", "Fabricación de motores", "Fabricación de componentes para automotrices", "Componentes eléctricos para vehículos", "Manufactura-Automotriz"),
    `Aeroespacial` = c("Aeroespacial", "Aeronaves", "Programa de lealtad"),
    `Agroindustria` = c("Agronegocios información y cultura", "Plataforma de comercio agrícola"),
    `Bebidas Alcohólicas` = c("Industria de las bebidas", "Producción y comercialización de bebidas alcohólicas", "Industria cervecera", "Bebidas Alcohólicas Industria cervecera"),
    `Comercio al por Mayor` = c("Comerciantes mayoristas de muebles y artículos para el hogar", "Empaquetado", "Comercio al por mayor", "Empaques de papel", "Fabricación de empaques de cartón y papel", "Fabricación de envases de cartón", "Empaques alimentos", "Producción de envases"),
    `Comercio al por Menor` = c("Alimentos y bebidas", "Producción de alimentos para mascotas", "Venta de artículos para el hogar", "Fabricación de lentes", "Producción de colchones", "perfumes y fragancias", "Fabricación de juguetes", "Comercio al por menor", "Fabricación de  herramientas para la construcción", "Comercio de materias primas para construcción", "Comercio de muebles y artículos del hogar", "Tiendas departamentales", "Fabricación de mobiliario", "Fabricación de productos de higiene personal", "Distribución de productos de acero y metal", "Productos para baño y cocina", "Mobiliaria", "Plataforma inmobiliaria", "Producción de juguetes", "Fabricación de muebles", "Mobiliario", "Producción de alimentos para mascotas", "Alimentos", "Elaboración de alimentos", "Comercio al por menor", "Alimentos y artículos de cuidado personal", "Ropa", "Inmuebles", "Fabricación de pinturas", "Fabricación de productos de limpieza y almacenamiento del hogar", "Producción de herramientas para la construcción", "Producción de herramientas para la construcción y herramientas eléctricas para uso en Exteriores", "Fabricación de mobiliario", "Fabricación de paneles de pantallas", "Producción de limpiaparabrisas", "Producción de contenidos", "Comercio electrónico", "Muebles"),
    `Construcción` = c("Construcción de obras de ingeniería civil", "Construcción", "Infraestructura", "Construcción de obras para transporte ferroviario", "Sector Inmobiliario Industrial", "Construcción de puertos", "Construcción de vías", "Construcción de obras", "Construcción de autopistas", "Edificación no residencial", "Bienes Raíces (Fibras)", "Construcción de obras de ingeniera civil"),
    `Deporte` = c("Liga de futbol", "Gimnasios"),
    `Educación` = c("Institución", "Educativa.", "Educación", "Institución Educativa."),
    `Electrónica` = c("Producción de semiconductores", "Servicios de producción electrónica", "Electrónica", "Componentes electrónicos", "Fabricación de componentes electrónicos", "Fabricación de interruptores electrónicos.", "Electrodomésticos", "Fabricación de semiconductores"),
    `Energía` = c("Energía", "Generación de energía", "Generación, transmisión y distribución de energía eléctrica", "Medidores de energía", "Producción de energía"),
    `Energía Renovable` = c("Energía solar", "Energía eólica", "Energías limpias", "Energías Renovables"),
    `Entretenimiento` = c("Entretenimiento", "Juegos de azar", "Venta de billetes de lotería", "Streaming y entretenimiento"),
    `Farmacéutico` = c("Farmacéutico", "Farmacéutica", "Fabricación de productos farmacéuticos", "Laboratorios médicos", "Industria farmacéutica"),
    `Financiero` = c("Arrendamiento financiero automotriz","Fondos de inversión", "Fondo de capital", "Servicios financieros", "Seguros de vida", "Casa de empeño", "Fondos de pensiones/", "Infraestructura social", "Financiamiento personal", "Sociedades financieras", "Instituciones de crédito", "Banca múltiple", "Grupo financiero", "Plataforma de servicios financieros", "Fondo de inversión"),
    `Hidrocarburos` = c("Industria petrolera", "Petroquímica", "Perforación de pozos petroleros y de gas", "Extracción de petróleo", "Producción de gasolina", "Hidrocarburos", "Extracción de gas natural no asociado", "Gas natural", "Extracción de gas natural"),
    `Hoteles` = c("Hoteles", "Servicios de alojamiento temporal", "Alquiler"),
    `Industria` = c("Sector Industrial", "Fabricación de calentadores industriales", "Fabricación de maquinaria pesada"),
    `Manufactura` = c("Manufacturera de productos domésticos de ventilación", "Manufactura", "Servicios de manufactura bajo contrato", "mejorar los procesos de manufactura", "Maquinaria para la industria", "Maquiladora para el rubro médico, aeroespacial, automotriz, tecnología y transporte", "Manufacturera de pisos vinílicos"),
    `Minería` = c("Minería", "Siderurgia", "Industria minera", "Otros servicios relacionados con la minería", "Fundición de metales", "Fabricación de acero", "Servicios relacionados con la minería"),
    `Química` = c("Química", "Producción de plásticos para la industria médica, eléctrico, automotriz y aeroespacial", "Elaboración de plásticos", "Fabricación de botellas de plástico", "Fabricación de gases industriales", "Plásticos", "Manufacturera de productos químicos"),
    `Salud` = c("Salud", "Fabricación de equipo médico"),
    `Servicios` = c("Agencias de viajes", "Servicios de Consultoría, Tecnología, Outsourcing, etc.", "Agencia de marketing", "Startup", "Capacitación", "Servicios portuarios", "Servicios logísticos", "Auditoría y control de calidad", "Servicios de gestión", "Outsourcing/servicio al cliente.", "Marketing digital", "Comercio electrónico y logística", "Aplicación para restaurantes"),
    `Tecnología` = c("Servicio de tecnología avanzada", "Desarrollo tecnológico (Digitalización)", "Tecnologías de la información", "Fabricación de pantallas de celular", "Tecnologías de la comunicación", "Desarrollo tecnológico", "Aplicación de restaurantes", "Software", "Ingeniería de software", "Plataforma tecnológica inmobiliaria", "Infraestructura tecnológica", "Manufactura de tecnologías", "TI", "Creación de Procesadores de cómputo"),
    `Telecomunicaciones` = c("Telecomunicaciones", "Data Centers", "Paquetería y mensajería", "Mensajería", "BPO", "Televisora", "Energía y telecomunicaciones", "Comunicación y Transporte", "Mensajería", "Fabricación de equipo de transmisión y recepción de señales de radio y televisión  y equipo de comunicación inalámbrico."),
    `Transporte` = c("Transporte", "Generación de electricidad y fabricación de trenes", "Transporte acuático", "Transporte ferroviario", "Construcción de vías de ferrocarril", "Aplicación de servicios de transporte particular", "producción de vagones de ferrocarril", "Fabricante de carros de ferrocarril", "Infraestructura y gestión de autopistas")
  ))



# Columnas de comprobación
columna_pais <- anuncios %>% group_by(pais) %>% count()
columna_empresa <- anuncios %>% group_by(empresa) %>% count()
columna_area <- anuncios %>% group_by(area) %>% count()
columna_estado <- anuncios %>% group_by(estado) %>% count()
columna_sector <- anuncios %>% group_by(sector) %>% count()

#---------------------------------------------------------------------------------------
# DATOS SE: ANUNCIOS DE INVERSIÓN POSTERIOR AL T-MEC | PRESENTAR INFORMACIÓN
#---------------------------------------------------------------------------------------

pais_n <- anuncios %>%  group_by(pais) %>% count() %>% arrange(desc(n))
pais_inv <- anuncios %>%  group_by(pais) %>% summarize(inversion_total = round(sum(inversion),1)) %>% arrange(desc(inversion_total))
pais <- pais_inv %>% left_join(pais_n, by = "pais") %>% rename(anuncios = n)

pais_sector <- anuncios %>% group_by(pais, area) %>% summarize(inversion_total = round(sum(inversion),1)) 

# Excel de NA's
write_xlsx(
  list("anuncios_na" = anuncios_na,
       "na_fecha" = anuncios_fecha_na,
       "na_empresa" = anuncios_empresa_na, 
       "pais_na" = anuncios_pais_na,
       "inversión_na" = anuncios_inversion_na,
       "proyecto_na" = anuncios_proyecto_na,
       "sector_na" = anuncios_area_na,
       "estado_na" = anuncios_estado_na),
  "/Users/antoniogarcia/Desktop/R/5. inversión/100. anuncios_na.xlsx", # Ruta Toño
  col_names = T
)


# Excel de Comprobación
write_xlsx(
  list("pais" = columna_pais,
       "empresa" = columna_empresa,
       "area" = columna_area, 
       "estado" = columna_estado,
       "sector" = columna_sector),
  "/Users/antoniogarcia/Desktop/R/5. inversión/200. anuncios_comprobación.xlsx", # Ruta Toño
  col_names = T
)
