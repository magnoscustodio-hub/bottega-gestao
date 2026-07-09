# GestãoSalão

Sistema de gestão de salão para restaurantes: onboarding do restaurante, login e o painel operacional diário (escala por praça, folgas, ausências, reservas).

## Stack

- React + Vite: página inicial (`/`) e login (`/login`) — um shell fino que leva para o painel.
- `public/onboarding.html` e `public/painel.html`: HTML/CSS/JS puros, servidos como estáticos pelo Vite, sem build. É onde a maior parte da aplicação vive de fato.
- Supabase (banco de dados, autenticação e RLS multi-tenant).

## Estrutura de pastas

```
src/
├── main.jsx                # ponto de entrada e rotas (Home, Login)
├── App.jsx / App.css
├── lib/
│   └── supabaseClient.js   # cliente Supabase configurado via variáveis de ambiente
└── pages/
    ├── Home.jsx             # página inicial (linka para onboarding.html/painel.html)
    └── Login.jsx            # login (Supabase Auth), redireciona para /painel.html

public/
├── onboarding.html   # wizard de cadastro: cria a conta do dono + restaurante + setores/praças/equipe/folgas no Supabase
└── painel.html       # painel operacional diário (calendário, escala por praça, folgas, ausências, reservas), carrega os dados do restaurante logado

supabase/
└── schema.sql        # schema completo (restaurantes, funcionarios, setores, pracas, pax_esperado, dias_fechados, folgas, ausencias, extras, reservas, escala_manual), todas com RLS

scripts/
└── migrar-bottega.mjs  # importação única dos dados já testados (Bottega Bernacca) para o Supabase
```

## Como rodar

1. Instale as dependências:
   ```
   npm install
   ```
2. Copie o arquivo de variáveis de ambiente e preencha com as chaves do seu projeto Supabase:
   ```
   cp .env.example .env
   ```
3. No SQL Editor do seu projeto Supabase, rode o script `supabase/schema.sql` (RLS habilitado em todas as tabelas).
4. Rode o servidor de desenvolvimento:
   ```
   npm run dev
   ```
5. Acesse `http://localhost:5173/onboarding.html` para cadastrar um restaurante, ou `http://localhost:5173/login` se já tiver conta.

## Fluxo

1. **Home (`/`)** → botão "Cadastrar restaurante" abre `/onboarding.html`; botão "Entrar" vai para `/login`.
2. **Onboarding** → ao finalizar, cria o usuário (Supabase Auth), o restaurante e toda a configuração inicial (setores, praças, equipe, PAX esperado, dias fechados, folgas) e redireciona para `/painel.html`.
3. **Login** → autentica e redireciona para `/painel.html`.
4. **Painel** → ao carregar, verifica a sessão; se não houver restaurante cadastrado para o usuário, manda para `/onboarding.html`. Todos os dados (equipe, praças, escala do mês, folgas, ausências, reservas) são carregados/gravados no Supabase filtrados pelo restaurante do usuário logado.

## Limitações conhecidas

- Praças cadastradas pelo onboarding não têm garçom preferencial (distribuição por rodízio simples); o dono ajusta manualmente pelo editor de escala do painel.
- O seletor de mês do painel cobre um intervalo fixo de meses (herdado do protótipo original).
- A agenda de compromissos do painel ainda usa `localStorage` do navegador, não Supabase.

## Roadmap

- [x] Estrutura inicial do projeto
- [x] Página inicial
- [x] Login
- [x] Onboarding conectado ao Supabase (cadastro de restaurante, setores, praças, equipe)
- [x] Painel operacional multi-tenant (escala, folgas, ausências, reservas)
