# 🌤️ Previsão do Tempo — Flutter

Aplicativo desenvolvido em **Flutter** para a **Atividade Avaliativa (Aula 9 · APIs remotas)** do curso de **Sistemas de Informação (Libertas)**. O app permite pesquisar cidades pelo nome e visualizar as condições meteorológicas atuais, horárias e diárias consumindo as APIs públicas da **Open-Meteo**.

---

## ✨ Funcionalidades

- **Busca de Cidades (Geocoding):** Pesquisa dinâmica pelo nome da cidade com retorno de até 10 localidades em português (`language=pt`), exibindo estado, país e coordenadas (`latitude` e `longitude`).
- **Condições Atuais (`current`):** Exibição da temperatura atual (`°C`), umidade relativa do ar (`%`), velocidade do vento (`km/h`), precipitação (`mm`) e volume de chuva (`mm`).
- **Previsão por Hora (`hourly`):** Lista horizontal com as próximas 24 horas contendo temperatura, probabilidade de chuva (`%`) e precipitação (`mm`).
- **Previsão Diária (`daily`):** Previsão estendida para 7 dias com temperaturas mínima e máxima, precipitação acumulada e probabilidade máxima de chuva.

---

## 🌐 APIs Utilizadas

1. **Open-Meteo Geocoding API** — Conversão do nome da cidade em coordenadas geográficas:
   ```text
   [https://geocoding-api.open-meteo.com/v1/search?name=](https://geocoding-api.open-meteo.com/v1/search?name=){cidade}&count=10&language=pt&format=json

   📸 Prints do Aplicativo
1. Busca e Listagem de Cidades
2. Previsão Atual, Horária e Diária
🛠️ Tecnologias e Dependências
Flutter & Dart (Material Design 3)

http — Consumo das APIs REST via requisições GET

🚀 Como Executar Localmente
1 - Clone este repositório e acesse a pasta do projeto: git clone [https://github.com/SEU-USUARIO/previsao_do_tempo.git](https://github.com/SEU-USUARIO/previsao_do_tempo.git)
cd previsao_do_tempo

2 - Instale as dependencias: flutter pub get

3 - Execute o aplicativo: flutter run

👤 Autor
Thalison Santos — Graduando em Sistemas de Informação (Libertas)