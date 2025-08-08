FROM mcr.microsoft.com/playwright:v1.54.0-noble

WORKDIR /playwright

COPY package.json package-lock.json .
RUN npm install

COPY . .
RUN npm run pw:install
