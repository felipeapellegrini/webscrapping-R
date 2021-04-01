## Webscrapping para busca de imoveis

# configura pasta de trabalho
base::setwd('C:/R-Projects/webscrapping-imoveis')

# zera td ----
base::rm(list = ls())

# carrega pckgs ----
pacman::p_load('RSelenium', 'plyr', 'dplyr', 'rvest', 'stringr', 'xlsx', 'mailR')

# ler o arquivo local (p/ não usar banco de dados) ----
local_file <- xlsx::read.xlsx('houses.xlsx', 1) %>%
  base::as.data.frame()

# abstracao dos links por partes  ----
base_link <- c('https://www.vivareal.com.br/')
route_params <- c('aluguel/sp/sao-jose-do-rio-preto/condominio_residencial/')
pagination <- c('?pagina=')
query_params <- c('#ordenar-por=preco:ASC&preco-ate=3000&preco-desde=2000&quartos=2&tipos=condominio_residencial,casa_residencial')

# Iniciar um servidor Selenium e criar instancia de browser ----
rD <- RSelenium::rsDriver(browser = 'chrome', port = 4545L, chromever = '89.0.4389.23')
remDr <- rD[['client']] # browser 

#rD$client$open() # caso o navegador feche

# navegar p/ site  ----
remDr$navigate(base::paste0(base_link,route_params,query_params))
base::Sys.sleep(5) # POG espera a pagina renderizar completamente


# armazena html do site ----
html <- rvest::read_html(remDr$getPageSource()[[1]])

# armazena numero de resultados p/ calcular qtd de paginas ----
outcome <- html %>% 
  rvest::html_nodes(".js-total-records") %>%
  rvest::html_text2() %>%
  base::as.numeric()

# armazena resultados por pagina ----
page_outcome <- html %>%
  rvest::html_nodes("[class='property-card__content-link js-card-title']") %>%
  rvest::html_text2() %>%
  base::length() %>%
  base::as.numeric()

# calcula qtd de paginas ----
pages <- 1:base::ceiling(outcome / page_outcome)

# declara objeto de resultados ----
houses <- base::data.frame()

# estrutura de loop para captura e armazenamento dos dados ----
for (p in pages) {
  page_link <- base::paste0(base_link,route_params,pagination,p,query_params)
  remDr$navigate(page_link)
  print(page_link)
  base::Sys.sleep(5)
  html <- rvest::read_html(remDr$getPageSource()[[1]])
  
  # armazena descricoes
  descriptions <- html %>%
    rvest::html_nodes("[class='results__content']") %>%
    rvest::html_nodes(".js-card-title .js-card-title") %>%
    rvest::html_text2()
  
  # armazena link do imovel
  paths <- html %>% 
    rvest::html_nodes("[class='results__content']") %>%
    rvest::html_nodes("[class='property-card__content-link js-card-title']") %>%
    rvest::html_attr("href") %>%
    stringr::str_remove("/")
  
  # armazena precos
  prices <- html %>%
    rvest::html_nodes("[class='results__content']") %>%
    rvest::html_nodes("[class='property-card__price js-property-card-prices js-property-card__price-small']") %>%
    rvest::html_text2() %>%
    base::substring(4) %>%
    stringr::str_remove_all(" /Mês")
  
  # armazena resultados no dataframe
  house_link <- base::paste0(base_link,paths)
  houses <- base::rbind(data.frame(descriptions, house_link, prices), houses)
  
}

# nomeia colunas do df ---- 
base::colnames(houses) <- c("Descricao", "Preco", "Link")

# armazena os novos imoveis anunciados ----
new_reg <- dplyr::anti_join(houses, local_file, by = 'Link') %>%
  base::as.data.frame()

# armazena os imoveis anunciados antes que não estão mais anunciados ----
deleted <- dplyr::anti_join(local_file, houses, by = 'Link') %>%
  base::as.data.frame()

# gera nova planilha com os imóveis anunciados ----
xlsx::write.xlsx(houses, 'houses.xlsx', sheetName = 'houses', row.names = FALSE)

# gerando variáveis para montar e-mail ----
nome <- c("Nome")
mail_houses <- c()
for (x in 1:5) {
  mail_houses[x] <- paste(houses[x,1],"<br>",
                    houses[x,2],"<br>",
                    houses[x,3],"<br><br><br>")
}

# gerando html de template para e-mail ----
mail_template <- base::paste0(
  "<h1>Olá ", nome,"!</h1><p>Tudo bem?<p>",
  "<br>",
  "<p>Veja o que eu encontrei na internet sobre casas para alugar </p> <br>",
  "<p>Ah, no final do e-mail eu anexei uma planilha com todas as ",outcome," casas encontradas.",
  "<br><br>",
  mail_houses[1], mail_houses[2], mail_houses[3], mail_houses[4], mail_houses[5]
)

# enviando e-mail com mailR ----
mailR::send.mail(
  from = "noreply.houses@gmail.com",
  to = "noreply.houses@gmail.com",
  subject = 'Encontre seu novo lar, doce lar!',
  body = mail_template,
  html = T,
  smtp = list(
    host.name = "smtp.gmail.com",
    port = 465,
    user.name = "noreply.houses@gmail.com",
    passwd = "123!@#asd",
    ssl = T
  ),
  authenticate = T,
  attach.files = 'C:/R-Projects/webscrapping-imoveis/houses.xlsx',
  send = T
)
