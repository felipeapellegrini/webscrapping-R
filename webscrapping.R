## Webscrapping para busca de imoveis

# zera td
rm(list = ls())

# carrega pckgs 
pacman::p_load('RSelenium', 'plyr', 'dplyr', 'rvest', 'stringr')



# abstracao dos links por partes 
base_link <- c('https://www.vivareal.com.br/')
route_params <- c('aluguel/sp/sao-jose-do-rio-preto/condominio_residencial/')
paginacao <- c('?pagina=')
query_params <- c('#ordenar-por=preco:ASC&preco-ate=3000&preco-desde=1200&quartos=2&tipos=condominio_residencial,casa_residencial')

# Iniciar um servidor Selenium e criar instancia de browser
rD <- RSelenium::rsDriver(browser = 'chrome', port = 4545L, chromever = '89.0.4389.23')
remDr <- rD[['client']] # browser 


# navegar p/ site 
remDr$navigate(c('https://www.vivareal.com.br/aluguel/sp/sao-jose-do-rio-preto/condominio_residencial/#ordenar-por=preco:ASC&preco-ate=3000&preco-desde=1200&quartos=2&tipos=condominio_residencial,casa_residencial'))

# armazena html do site
html <- rvest::read_html(remDr$getPageSource()[[1]])

# armazena numero de resultados p/ calcular qtd de paginas
resultados <- html %>% 
  rvest::html_nodes(".js-total-records") %>%
  rvest::html_text2() %>%
  as.numeric()


# calcula qtd de paginas
pages <- 1:base::ceiling(resultados / length(paths))

## Du, a ideia aqui é ter uma variável que faça a junção dos 3 textos (base_link, route_params e query_params)
### até pq eu ainda vou criar um for pra percorrer todas as paginas, dai vou ter q manipular uma nova variavel de texto


# armazena descricoes
descriptions <- html %>%
  rvest::html_nodes(".js-card-title .js-card-title") %>%
  rvest::html_text2()

# armazena link do imovel
paths <- html %>% 
  rvest::html_nodes("[class='property-card__content-link js-card-title']") %>%
  rvest::html_attr("href")


# armazena precos
prices <- html %>%
  rvest::html_nodes(".js-card-title p") %>%
  rvest::html_text2() %>%
  base::substring(4) %>%
  stringr::str_remove_all(" /Mês")



