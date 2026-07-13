require "import"
crypt = require "crypt"
json = require "cjson"
import "java.io.*"
import "com.androlua.*"
import "android.graphics.Bitmap"
import "java.util.Locale"

local config = require("config")
-- Variáveis globais
configPath = "/sdcard/config.json"  -- Caminho do arquivo de configuração

-- Função para recuperar os dois primeiros caracteres do código de idioma
function getLanguageCode()
    local locale = Locale.getDefault()
    local language = tostring(locale)  -- Converte o objeto para string completa (ex: "pt_BR")
    local langCode = string.sub(language, 1, 2)  -- Extrai os primeiros dois caracteres
    return langCode
end

-- Variáveis globais
local idioma = getLanguageCode()
traducoes = config.idiomas[idioma] or config.idiomas["en"]
local selectedApi = nil
local dlg = nil

-- Gemini model and API key
gemini_model = "gemini-2.5-flash"
API_KEY = nil

-- Grok API configuration
grok_model = "grok-4-1-fast-reasoning"
GROK_API_KEY = nil

-- Função para carregar o arquivo de configuração
function loadConfig()
    local file = io.open(configPath, "r")
    if file then
        local content = file:read("*a")
        file:close()
        return json.decode(content)
    else
        return nil
    end
end

-- Função para salvar as configurações
function saveConfig(config)
    local file = io.open(configPath, "w")
    if file then
        file:write(json.encode(config))
        file:close()
    else
        print(traducoes["ERRO_SALVAR_CONFIGURACOES"])
    end
end

-- obter configurações do usuário
function showConfigDialog()
    local options = {traducoes["SIM"], traducoes["NAO"]}
    local optionsSpeak = {traducoes["DIRETAMENTE"], traducoes["EM_DIALOGO"]}

    local dlgSave = LuaDialog().setTitle(traducoes["SALVAR_IMAGENS_DISPOSITIVO"])
                        .setItems(options)
                        .show()

    local saveImages = false
    local copyToClipboard = false

    local function showSpeakDialog()
        -- Exibe o diálogo para escolher se mostrar a descrição em diálogo ou diretamente
        local dlgSpeak = LuaDialog().setTitle(traducoes["FALAR_DIALOGO"])
                            .setItems(optionsSpeak)
                            .show()

        dlgSpeak.onItemClick = function(l, v, p, i)
            dlgSpeak.dismiss()

            local speakDirectly = i == 1  -- 1 para "diretamente", 2 para "em diálogo"

            -- Salva a configuração
            saveConfig({saveImages = saveImages, copyToClipboard = copyToClipboard, speakDirectly = speakDirectly, grokApiKey = GROK_API_KEY, geminiApiKey = API_KEY, selectedApi = selectedApi})

            -- Exibir o diálogo de escolha após configurar
            showOptionsDialog()
        end
    end

    local speakDialogRef = showSpeakDialog

    dlgSave.onItemClick = function(l, v, p, i)
        dlgSave.dismiss()

        saveImages = i == 1  -- 1 para "Sim", 2 para "Não"

        if saveImages then
            -- Se a pessoa quer salvar a imagem, exibe o diálogo para copiar o nome
            local dlgCopy = LuaDialog().setTitle(traducoes["COPIAR_NOME_IMAGEM"])
                                .setItems(options)
                                .show()

            local copyToClipboardVar = false
            dlgCopy.onItemClick = function(l, v, p, i)
                dlgCopy.dismiss()

                copyToClipboardVar = i == 1  -- 1 para "Sim", 2 para "Não"
                copyToClipboard = copyToClipboardVar
                speakDialogRef()
            end
        else
            copyToClipboard = false
            speakDialogRef()
        end
    end
end

-- Função para exibir diálogo de configuração de API keys
function showApiKeysDialog()
    import "android.widget.LinearLayout"
    import "android.widget.RadioGroup"
    import "android.widget.RadioButton"
    import "android.widget.EditText"

    local layout = LinearLayout(this)
    layout.setOrientation(LinearLayout.VERTICAL)
    layout.setPadding(16, 16, 16, 16)

    -- RadioGroup para seleção da API
    local radioGroup = RadioGroup(this)
    radioGroup.setOrientation(LinearLayout.VERTICAL)

    local radioBtnGrok = RadioButton(this)
    radioBtnGrok.setText("Grok (xAI)")
    radioBtnGrok.setId(1)

    local radioBtnGemini = RadioButton(this)
    radioBtnGemini.setText("Gemini (Google)")
    radioBtnGemini.setId(2)

    radioGroup.addView(radioBtnGrok)
    radioGroup.addView(radioBtnGemini)
    radioGroup.check(selectedApi == "gemini" and 2 or 1)

    layout.addView(radioGroup)

    -- Campo de edição para a chave
    local editKey = EditText(this)
    editKey.setInputType(129)
    layout.addView(editKey)

    -- Atualizar hint e valor do editText quando mudar seleção
    local updateEditText = function()
        local selectedId = radioGroup.getCheckedRadioButtonId()
        selectedApi = selectedId == 2 and "gemini" or "grok"
        local currentKey = selectedApi == "grok" and (GROK_API_KEY or "") or (API_KEY or "")
        editKey.setHint(selectedApi == "grok" and traducoes["CHAVE_GROK"] or traducoes["CHAVE_GEMINI"])
        editKey.setText(currentKey)
    end

    updateEditText()

    radioGroup.setOnCheckedChangeListener(function(group, checkedId)
        updateEditText()
    end)

    LuaDialog()
        .setTitle(traducoes["CONFIGURAR_API_KEYS"])
        .setView(layout)
        .setPositiveButton(traducoes["SIM"], function()
            if selectedApi == "grok" then
                GROK_API_KEY = editKey.getText().toString()
            else
                API_KEY = editKey.getText().toString()
            end
            showConfigDialog()
        end)
        .setNegativeButton(traducoes["NAO"], function()
            showConfigDialog()
        end)
        .show()
end

-- Função para verificar se as configurações já existem ou precisam ser definidas
function checkAndSetupConfig()
    local loadedConfig = loadConfig()
    if loadedConfig == nil then
        showApiKeysDialog()
    else
        -- Carrega as chaves de API do config salvo
        if loadedConfig.grokApiKey then
            GROK_API_KEY = loadedConfig.grokApiKey
        end
        if loadedConfig.geminiApiKey then
            API_KEY = loadedConfig.geminiApiKey
        end
        if loadedConfig.selectedApi then
            selectedApi = loadedConfig.selectedApi
        end
        return loadedConfig
    end
end

-- Função para obter a API selecionada pelo usuário
function getSelectedApi()
    return selectedApi or "grok"
end

-- Função para processar a imagem com a API selecionada
function processImageWithSelectedApi(base64Image)
    local api = getSelectedApi()
    if api == "gemini" then
        processImage(base64Image)
    else
        processImageGrok(base64Image)
    end
end

-- Função para processar a imagem via Grok API
function processImageGrok(base64Image)
    local headers = {
        ["Content-Type"] = "application/json",
        ["Authorization"] = "Bearer " .. GROK_API_KEY
    }

    local langNormalized = (idioma or "pt-BR"):gsub("%-%-?", "_")
    if langNormalized == "" then langNormalized = "pt_BR" end

    local promptText = "Describe the image objectively in " .. langNormalized .. ", providing a clear overview of visible elements for visually impaired users. Follow these rules strictly:\n\n- Start with general scene (who/what/where).\n- Highlight main action and key elements.\n- Transcribe all visible text verbatim.\n- Use present tense and active verbs.\n- Focus on relevant visual information only.\n- No introductions, opinions, 'image of', emojis, or redundant phrases.\n- Answer only in " .. langNormalized .. ", pure description.\n\nDescribe following this exact structure."

    local requestBody = {
        input = {
            {
                role = "user",
                content = {
                    {
                        type = "input_image",
                        image_url = "data:image/jpeg;base64," .. base64Image,
                        detail = "high"
                    },
                    {
                        type = "input_text",
                        text = promptText
                    }
                }
            }
        },
        model = grok_model
    }

    local url = "https://api.x.ai/v1/responses"

    Http.post(url, json.encode(requestBody), headers, function(status, body)
        if status == 200 then
            local response = json.decode(body)
            local config = checkAndSetupConfig()

            if response and response.output and #response.output > 0 then
                -- Iterar por todos os outputs (não apenas o primeiro)
                local description = nil
                for _, output in ipairs(response.output) do
                    if output.content and #output.content > 0 then
                        for _, content in ipairs(output.content) do
                            if content.type == "output_text" and content.text then
                                description = content.text
                                break
                            end
                        end
                        if description then break end
                    end
                end

                if description then
                    showDescriptionDialog(description)
                    if config and config.speakDirectly then
                        this.speak(description)
                    end
                else
                    print(traducoes["ERRO_OBTER_RESULTADO"])
                end
            else
                print(traducoes["ERRO_OBTER_RESULTADO"])
            end
        else
            print("Grok Error " .. status .. ": " .. body)
        end
    end)
end

-- Função para processar a imagem via Gemini API (método antigo mantido)
function processImage(base64Image)
    local headers = {
        ["Content-Type"] = "application/json"
    }

    local langNormalized = (idioma or "pt-BR"):gsub("%-%-?", "_")
    if langNormalized == "" then langNormalized = "pt_BR" end

    local promptText = "Describe the image objectively in " .. langNormalized .. ", providing a clear overview of visible elements for visually impaired users. Follow these rules strictly:\n\n- Start with general scene (who/what/where).\n- Highlight main action and key elements.\n- Transcribe all visible text verbatim.\n- Use present tense and active verbs.\n- Focus on relevant visual information only.\n- No introductions, opinions, 'image of', emojis, or redundant phrases.\n- Answer only in " .. langNormalized .. ", pure description.\n\nDescribe following this exact structure."

    local requestBody = {
        systemInstruction = {
            parts = {
                { text = promptText }
            }
        },
        contents = {
            {
                role = "user",
                parts = {
                    { inlineData = { mimeType = "image/jpeg", data = base64Image } }
                }
            }
        }
    }

    local url = "https://generativelanguage.googleapis.com/v1beta/models/" .. gemini_model .. ":generateContent?key=" .. API_KEY

    Http.post(url, json.encode(requestBody), headers, function(status, body)
        if status == 200 then
            local response = json.decode(body)
            local config = checkAndSetupConfig()

            local candidate = nil
            if response and response.candidates and #response.candidates > 0 then
                candidate = response.candidates[1]
            end

            if candidate and candidate.content and candidate.content.parts then
                local textPart = nil
                for _, p in ipairs(candidate.content.parts) do
                    if type(p.text) == "string" then
                        textPart = p
                        break
                    end
                end

                if textPart and textPart.text then
                    showDescriptionDialog(textPart.text)
                    if config and config.speakDirectly then
                        this.speak(textPart.text)
                    end
                else
                    print(traducoes["ERRO_OBTER_RESULTADO"])
                end
            else
                print(traducoes["ERRO_OBTER_RESULTADO"])
            end
        else
            print("Gemini Error " .. status .. ": " .. body)
        end
    end)
end

-- Função para exibir a descrição da imagem em um diálogo
function showDescriptionDialog(description)
    import "android.widget.LinearLayout"
    import "android.widget.TextView"
    import "android.widget.ScrollView"
    import "android.view.ViewGroup"

    local idioma = getLanguageCode()
    local trad = config.idiomas[idioma] or config.idiomas["en"]

    local mainLayout = LinearLayout(this)
    mainLayout.setOrientation(LinearLayout.VERTICAL)
    mainLayout.setPadding(16, 16, 16, 16)

    local scrollView = ScrollView(this)
    local params = ViewGroup.LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT, 400)
    scrollView.setLayoutParams(params)

    local layout = LinearLayout(this)
    layout.setOrientation(LinearLayout.VERTICAL)

    local textView = TextView(this)
    textView.setText(description)
    textView.setTextSize(16)
    textView.setTextIsSelectable(true)
    layout.addView(textView)

    scrollView.addView(layout)
    mainLayout.addView(scrollView)

    LuaDialog()
        .setTitle(trad["DESCRICAO_IMAGEM"])
        .setView(mainLayout)
        .setPositiveButton(trad["COPIAR"], function()
            service.copy(description)
            this.speak(trad["COPIADO"])
        end)
        .setNegativeButton(trad["FECHAR"], function()
        end)
        .show()
end

-- Função para garantir que a pasta exista
function ensureDirectoryExists(directoryPath)
    local dir = File(directoryPath)
    if not dir.exists() then
        dir.mkdirs()
    end
end

-- Função para gerar um nome de arquivo único
function generateImageName()
    local timestamp = os.time()
    local randomNum = math.random(1000, 9999)
    return string.format("image_%d_%d.jpg", timestamp, randomNum)
end

-- Função para capturar e processar a imagem
function captureAndProcessImage(focus)
    local config = checkAndSetupConfig()

    local directoryPath = focus == 1 and "/sdcard/bemyeyes/obj" or "/sdcard/bemyeyes/prints"
    local tempDir = "/sdcard/cache/"
    local imageName = generateImageName()

    if not config.saveImages then
        ensureDirectoryExists(tempDir)
        directoryPath = tempDir
        imageName = "image.jpg"
    else
        ensureDirectoryExists(directoryPath)
    end
    
    local imagePath = directoryPath .. "/" .. imageName

    local screenCaptureFunc = function(bmp)
        bmp.compress(Bitmap.CompressFormat.PNG, 90, FileOutputStream(File(imagePath)))

        this.speak(traducoes["PROCESSANDO_IMAGEM"])

        task(300, function()
            local fl = io.open(imagePath, "rb")
            local tfl = fl:read("*a")
            fl:close()
            processImageWithSelectedApi(crypt.base64encode(tfl))

            if config and config.copyToClipboard then
                service.copy(imageName)
            end
        end)
    end

    if focus == 1 then
        task(300, function()
            this.getScreenShot(node, {onScreenCaptureDone = screenCaptureFunc})
        end)
    else
        task(300, function()
            this.getScreenShot({onScreenCaptureDone = screenCaptureFunc})
        end)
    end
end

-- Função para exibir o diálogo de escolha com layout personalizado
function showOptionsDialog()
    import "android.widget.LinearLayout"
    import "android.widget.Button"
    import "android.view.ViewGroup"

    local idioma = getLanguageCode()
    local trad = config.idiomas[idioma] or config.idiomas["en"]

    local layout = LinearLayout(this)
    layout.setOrientation(LinearLayout.VERTICAL)
    layout.setPadding(20, 20, 20, 20)

    -- Botão Reconhecimento do item em foco
    local btnFoco = Button(this)
    btnFoco.setText(trad["RECONHECIMENTO_ITEM_FOCO"])
    btnFoco.setTextSize(16)
    local paramsFoco = ViewGroup.LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT, 100)
    btnFoco.setLayoutParams(paramsFoco)
    btnFoco.setOnClickListener(function()
        dlg.dismiss()
        captureAndProcessImage(1)
    end)
    layout.addView(btnFoco)

    -- Espaço entre botões
    local space1 = LinearLayout(this)
    local paramsSpace = ViewGroup.LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT, 20)
    space1.setLayoutParams(paramsSpace)
    layout.addView(space1)

    -- Botão Reconhecimento de toda a tela
    local btnTela = Button(this)
    btnTela.setText(trad["RECONHECIMENTO_TELA_COMPLETA"])
    btnTela.setTextSize(16)
    local paramsTela = ViewGroup.LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT, 100)
    btnTela.setLayoutParams(paramsTela)
    btnTela.setOnClickListener(function()
        dlg.dismiss()
        captureAndProcessImage(2)
    end)
    layout.addView(btnTela)

    -- Espaço entre botões
    local space2 = LinearLayout(this)
    space2.setLayoutParams(paramsSpace)
    layout.addView(space2)

    -- Botão Fechar
    local btnFechar = Button(this)
    btnFechar.setText(trad["FECHAR"])
    btnFechar.setTextSize(16)
    local paramsFechar = ViewGroup.LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT, 100)
    btnFechar.setLayoutParams(paramsFechar)
    btnFechar.setOnClickListener(function()
        dlg.dismiss()
    end)
    layout.addView(btnFechar)

    dlg = LuaDialog()
        .setTitle(trad["OPCOES"])
        .setView(layout)
        .show()
end

-- Verificação da configuração antes de exibir o diálogo de opções
if checkAndSetupConfig() then
    showOptionsDialog()
end