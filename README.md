# NovelHub

Um aplicativo Flutter repleto de recursos para leitura e gerenciamento de novels de múltiplas fontes online. O NovelHub agrega conteúdo de diversas plataformas e oferece uma experiência de leitura aprimorada com funcionalidade de exportação em formato EPUB.

## ✨ Recursos

* **Agregação Multiplataforma**: Pesquise e leia novels de várias fontes, incluindo CentralNovel, Illusia e NovelMania
* **Busca Abrangente**: Encontre novels por título em todas as fontes integradas
* **Informações Detalhadas**: Veja descrições, capas, gêneros e listas de capítulos das novels
* **Leitura Aprimorada**: Leia capítulos em uma interface limpa e sem distrações, com botões de navegação anterior/próximo
* **Gerenciamento de Capítulos**: Navegue pelos capítulos com opções de ordenação e fácil acesso
* **Exportação para EPUB**: Baixe novels completas ou capítulos selecionados para leitura offline
* **Downloads Personalizados**: Escolha intervalos específicos de capítulos para gerar arquivos EPUB
* **Tema Escuro**: Interface em modo escuro para leitura confortável

## 🛠️ Tecnologias Utilizadas

* **Flutter**: Framework para desenvolvimento de aplicativos multiplataforma
* **Dart**: Linguagem de programação usada pelo Flutter
* **Análise de HTML**: Extração e tratamento de conteúdo de sites de novels
* **Cliente HTTP (Dio)**: Gerenciamento de requisições e scraping de dados
* **Arquivos (Zip)**: Criação de arquivos EPUB (que são essencialmente arquivos ZIP)
* **Path Provider**: Gerenciamento de diretórios e caminhos de armazenamento para downloads

## ⚙️ Requisitos

* Flutter SDK (versão 3.9.0 ou superior)
* Dart SDK (versão 3.9.0 ou superior)
* Conexão com a internet para buscar conteúdo das novels

## 🚀 Iniciando o Projeto

### Pré-requisitos

Certifique-se de que o Flutter está instalado. Caso não esteja, siga o [guia oficial de instalação](https://flutter.dev/docs/get-started/install).

### Instalação

1. Clone o repositório:

```bash
git clone https://github.com/your-username/NovelHub.git
cd NovelHub
```

2. Instale as dependências:

```bash
flutter pub get
```

3. Execute o aplicativo:

```bash
flutter run
```

### Gerar Versão de Produção

Para compilar a versão de release do app:

```bash
flutter build apk --release
```

## 📖 Uso

1. **Pesquisar Novels**: Use a barra de busca na tela inicial para procurar novels em todas as fontes integradas
2. **Explorar Lançamentos Recentes**: Veja as últimas atualizações das plataformas quando não estiver pesquisando
3. **Ler Novels**: Toque em qualquer novel para visualizar seus detalhes e capítulos
4. **Navegar entre Capítulos**: Use os botões anterior/próximo na parte inferior da tela de leitura
5. **Exportar como EPUB**: Toque no ícone de download na tela de detalhes para gerar um arquivo EPUB
6. **Downloads Personalizados**: Selecione capítulos específicos para incluir na exportação

## 🧩 Arquitetura

O aplicativo segue uma arquitetura modular com os seguintes componentes principais:

### Models

* `NovelSearchResult`: Representa uma novel nos resultados de busca
* `NovelInfo`: Contém informações detalhadas sobre uma novel
* `ChapterContent`: Armazena o conteúdo de um capítulo com dados de navegação

### Services

* `NovelApiService`: Responsável por buscar dados das fontes via scraping
* Suporte a múltiplas plataformas (CentralNovel, Illusia, NovelMania)

### Screens

* `HomeScreen`: Tela principal de busca e navegação
* `NovelDetailPage`: Exibe detalhes, descrição, gêneros e capítulos da novel
* `ChapterDetailPage`: Mostra o conteúdo de cada capítulo com navegação
* `EpubDownloaderPage`: Gerencia a criação e o download de arquivos EPUB

## 🌐 Fontes Suportadas

* **CentralNovel**: Plataforma brasileira de novels
* **Illusia**: Plataforma de leitura de novels em português
* **NovelMania**: Plataforma agregadora de novels em português

## ⚙️ Configuração

O aplicativo pode ser configurado através do arquivo `pubspec.yaml`. Dependências principais incluem:

* `dio`: Cliente HTTP para requisições web
* `html`: Análise e extração de conteúdo HTML
* `archive`: Criação de arquivos ZIP/EPUB
* `path_provider`: Gerenciamento de diretórios e caminhos locais
* `file_picker`: Interface para seleção de arquivos

## 🤝 Contribuindo

1. Faça um fork do repositório
2. Crie um branch de funcionalidade (`git checkout -b feature/nova-funcionalidade`)
3. Faça suas alterações (`git commit -m 'Adiciona nova funcionalidade'`)
4. Envie o branch (`git push origin feature/nova-funcionalidade`)
5. Abra um Pull Request

## 🐞 Problemas e Bugs

Se encontrar algum problema ou bug, abra uma issue no repositório com informações detalhadas e passos para reproduzir o erro.

## 💬 Suporte

Para suporte, abra uma issue no repositório ou entre em contato com os mantenedores do projeto.

---

**Nota**: Este aplicativo realiza web scraping para agregar conteúdo de diferentes plataformas de novels. Respeite os termos de uso dessas plataformas e utilize o aplicativo de forma responsável.
