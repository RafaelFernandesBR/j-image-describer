# Image Describer - Descritor de Imagens para Jieshu

Uma extensão para o **leitor de telas Jieshu** (Android) que usa IA para descrever imagens de forma clara e objetiva para pessoas com deficiência visual.

## 🎯 O que é?

Image Describer é uma ferramenta que permite aos usuários do Jieshu descrever qualquer imagem na tela simplesmente ativando o script. A extensão captura a imagem e usa inteligência artificial para gerar uma descrição, falando ou exibindo em um diálogo personalizado.

## ✨ Features

- **Dois modos de captura:**
  - Descrever item em foco
  - Descrever tela inteira

- **Suporte a duas IAs:**
  - Grok (xAI)
  - Gemini (Google)
  - Escolha qual usar na primeira configuração

- **Múltiplos idiomas:**
  - Português
  - Inglês
  - Fácil adicionar novos idiomas

- **Interface personalizada:**
  - Diálogos com layouts customizados
  - Botão para copiar descrição
  - Configuração de preferências na primeira execução

- **Armazenamento inteligente:**
  - Opção de salvar imagens no dispositivo
  - Cópia do nome do arquivo para clipboard

## 🚀 Como usar

1. Instale a extensão no Jieshu
2. Na primeira execução, configure:
   - Qual API usar (Grok ou Gemini)
   - Sua chave de API
   - Preferências de salvamento
3. Ative o script quando quiser descrever uma imagem
4. Escolha se deseja descrever o item em foco ou a tela inteira
5. Aguarde a IA processar e receberá a descrição

## 📋 Requisitos

- **Jieshu** (leitor de telas Android)
- Uma chave de API válida:
  - Grok (xAI): https://console.x.ai
  - Gemini (Google): https://aistudio.google.com

## ⚙️ Configuração

As configurações são salvas automaticamente em `/sdcard/config.json` após a primeira execução:

```json
{
  "saveImages": true,
  "copyToClipboard": true,
  "speakDirectly": false,
  "selectedApi": "grok",
  "grokApiKey": "sua-chave-aqui",
  "geminiApiKey": "sua-chave-aqui"
}
```

## 🗣️ Idiomas

A extensão detecta automaticamente o idioma do dispositivo. Atualmente suporta:
- 🇧🇷 Português
- 🇺🇸 Inglês

Quer adicionar seu idioma? É fácil! Abra `config.lua` e adicione uma nova seção de tradução.
