require "import"
crypt = require "crypt"
json = require "cjson"
import "java.io.*"
import "com.androlua.*"
import "android.graphics.Bitmap"
import "java.util.Locale"

local config = require("config")
-- Variáveis globais
vision_api_url = "https://visionbot.ru/apiv2/in.php"
result_url = "https://visionbot.ru/apiv2/res.php"
configPath = "/sdcard/config.json"  -- Caminho do arquivo de configuração

-- Função para recuperar os dois primeiros caracteres do código de idioma
function getLanguageCode()
    local locale = Locale.getDefault()
    local language = tostring(locale)  -- Converte o objeto para string completa (ex: "pt_BR")
    local langCode = string.sub(language, 1, 2)  -- Extrai os primeiros dois caracteres
    return langCode
end

-- Variáveis globais
local resultFound = false  -- Variável para parar a execução quando o resultado for encontrado
-- Defina o idioma do dispositivo e as traduções
local idioma = getLanguageCode()
local traducoes = config.idiomas[idioma] or config.idiomas["pt_BR"]

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

-- Função para exibir o diálogo de configuração para copiar e salvar imagens
function showConfigDialog()
    local options = {traducoes["SIM"], traducoes["NAO"]}

    local dlgSave = LuaDialog().setTitle(traducoes["SALVAR_IMAGENS_DISPOSITIVO"])
                        .setItems(options)
                        .show()

    dlgSave.onItemClick = function(l, v, p, i)
        dlgSave.dismiss()

        local saveImages = i == 1  -- 1 para "Sim", 2 para "Não"

        if saveImages then
            -- Se a pessoa quer salvar a imagem, exibe o diálogo para copiar o nome
            local dlgCopy = LuaDialog().setTitle(traducoes["COPIAR_NOME_IMAGEM"])
                                .setItems(options)
                                .show()

            dlgCopy.onItemClick = function(l, v, p, i)
                dlgCopy.dismiss()

                local copyToClipboard = i == 1  -- 1 para "Sim", 2 para "Não"

                -- Salva ambas as configurações no arquivo
                local config = {copyToClipboard = copyToClipboard, saveImages = saveImages}
                saveConfig(config)

                -- Exibir o diálogo de escolha após configurar
                showOptionsDialog()
            end
        else
            -- Se a pessoa não quer salvar a imagem, não copia o nome e salva a configuração
            local config = {copyToClipboard = false, saveImages = saveImages}
            saveConfig(config)

            -- Exibir o diálogo de escolha após configurar
            showOptionsDialog()
        end
    end
end

-- Função para verificar se as configurações já existem ou precisam ser definidas
function checkAndSetupConfig()
    local config = loadConfig()
    if config == nil then
        showConfigDialog()
    else
        return config
    end
end

-- Função para obter resultado
function getRecognitionResult(reqId, attempt)
    if resultFound or attempt > 30 then
        if attempt > 30 then
            print(traducoes["TEMPO_LIMITE_EXCEDIDO"])
        end
        return
    end

    Http.post(result_url, {id = reqId}, {}, function(status, body)
        if status == 200 then
            local result = json.decode(body)
            if result.status == "ok" then
                resultFound = true
                print(result.text)
                return
            elseif result.status == "notready" then
                task(3000, function()
                    getRecognitionResult(reqId, attempt + 1)
                end)
            else
                print(traducoes["ERRO_OBTER_RESULTADO"] .. result.status)
            end
        else
            print(traducoes["ERRO_REQUISICAO"] .. status)
        end
    end)
end

-- Função para fazer o upload da imagem para a API
function uploadImage(base64Image, language, beMyAI)
    local bm = beMyAI and '1' or '0'

    Http.post(vision_api_url, {
        body = base64Image,
        lang = language,
        target = 'nothing',
        bm = bm
    }, {}, function(status, body)
        if status == 200 then
            local responseJson = json.decode(body)
            if responseJson.status == 'ok' then
                resultFound = false
                getRecognitionResult(responseJson.id, 1)
            else
                print(traducoes["ERRO_OBTER_RESULTADO"] .. responseJson.status)
            end
        else
            print(traducoes["ERRO_REQUISICAO"] .. status)
        end
    end)
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

-- Função para capturar e processar a imagem via API
function captureAndProcessImage(focus)
    local config = checkAndSetupConfig()

    -- Diretório para salvar as imagens
    local directoryPath = focus == 1 and "/sdcard/bemyeyes/obj" or "/sdcard/bemyeyes/prints"
    
    -- Diretório temporário para imagens (caso o usuário não queira salvar permanentemente)
    local tempDir = "/sdcard/cache/"
    local imageName = generateImageName()

        -- Se o usuário não deseja salvar, usamos o diretório de cache temporário
        if not config.saveImages then
            ensureDirectoryExists(tempDir)
            directoryPath = tempDir
            imageName = "image.jpg"
        else
            ensureDirectoryExists(directoryPath)
        end
    
    local imagePath = directoryPath .. "/" .. imageName

    local screenCaptureFunc = function(bmp)
        -- Salva a imagem, mesmo que temporariamente
        bmp.compress(Bitmap.CompressFormat.PNG, 90, FileOutputStream(File(imagePath)))

        this.speak(traducoes["PROCESSANDO_IMAGEM"])
        task(300, function()
            local fl = io.open(imagePath, "rb")
            local tfl = fl:read("*a")
            fl:close()
            uploadImage(crypt.base64encode(tfl), idioma, true)

            -- Se a opção de copiar estiver ativa, copia o nome da imagem
            if config and config.copyToClipboard then
                service.copy(imageName)
            end
        end)
    end

    if focus == 1 then
        task(80, function()
            this.getScreenShot(node, {onScreenCaptureDone = screenCaptureFunc})
        end)
    else
        task(80, function()
            this.getScreenShot({onScreenCaptureDone = screenCaptureFunc})
        end)
    end
end

-- Função para exibir o diálogo de escolha
function showOptionsDialog()
    local t = {traducoes["RECONHECIMENTO_ITEM_FOCO"], traducoes["RECONHECIMENTO_TELA_COMPLETA"]}
    local dlg = LuaDialog().setItems(t).show()
    dlg.onItemClick = function(l, v, p, i)
        dlg.dismiss()
        captureAndProcessImage(i)
    end
end

-- Verificação da configuração antes de exibir o diálogo de opções
if checkAndSetupConfig() then
    showOptionsDialog()
end
