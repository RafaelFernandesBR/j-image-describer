-- Configuration file for language support
-- To add support for your language, follow these steps:
-- 1. Create a new table for your language, using the 2-letter language code as the key (e.g. "fr" for French, "es" for Spanish, etc.)
-- 2. Translate the text for each key in the table
-- 3. Add the new table to the "idiomas" table

local config = {
  idiomas = {
    -- Portuguese (pt)
    ["pt"] = {
      ["RECONHECIMENTO_ITEM_FOCO"] = "Reconhecimento do item em Foco",
      ["RECONHECIMENTO_TELA_COMPLETA"] = "Reconhecimento de toda a tela",
      ["SALVAR_IMAGENS_DISPOSITIVO"] = "Deseja salvar as imagens no dispositivo?",
      ["COPIAR_NOME_IMAGEM"] = "Copiar imagem para área de transferência?",
      ["ERRO_SALVAR_CONFIGURACOES"] = "Erro ao salvar configurações.",
      ["ERRO_OBTER_RESULTADO"] = "Erro ao obter o resultado: ",
      ["ERRO_REQUISICAO"] = "Erro na requisição: ",
      ["TEMPO_LIMITE_EXCEDIDO"] = "Tempo limite excedido",
      ["PROCESSANDO_IMAGEM"] = "Processando imagem, aguarde.",
      ["SIM"] = "Sim",
      ["NAO"] = "Não",
    },
    -- English (en)
    ["en"] = {
      ["RECONHECIMENTO_ITEM_FOCO"] = "Item Recognition",
      ["RECONHECIMENTO_TELA_COMPLETA"] = "Full Screen Recognition",
      ["SALVAR_IMAGENS_DISPOSITIVO"] = "Do you want to save images on the device?",
      ["COPIAR_NOME_IMAGEM"] = "Copy image to clipboard?",
      ["ERRO_SALVAR_CONFIGURACOES"] = "Error saving settings.",
      ["ERRO_OBTER_RESULTADO"] = "Error getting result: ",
      ["ERRO_REQUISICAO"] = "Error in request: ",
      ["TEMPO_LIMITE_EXCEDIDO"] = "Time limit exceeded",
      ["PROCESSANDO_IMAGEM"] = "Processing image, please wait.",
      ["SIM"] = "Yes",
      ["NAO"] = "No",
    },
    -- Add your language here, for example:
    -- ["fr"] = {
    --   ["RECONHECIMENTO_ITEM_FOCO"] = "Reconnaissance de l'item en focus",
    --   ["RECONHECIMENTO_TELA_COMPLETA"] = "Reconnaissance de l'écran complet",
    --   ...
    -- }
  }
}

-- Note: Currently, only 2-letter language codes are supported (e.g. "pt", "en", "fr", etc.)
-- If you need to support a language with a longer code (e.g. "pt_BR", "en_US"), you will need to modify the code to handle this.

return config
