-- Thanks to Ashish Kaushik, who helped me with the Lua language.

require "import"
crypt = require "crypt"
json = require "cjson"
import "java.io.*"
import "com.androlua.*"
import "android.graphics.Bitmap"
import "java.util.Locale"

vision_api_url = "https://visionbot.ru/apiv2/in.php"
result_url = "https://visionbot.ru/apiv2/res.php"

local resultFound = false  -- Variável para parar a execução quando o resultado for encontrado

-- Função para recuperar os dois primeiros caracteres do código de idioma
function getLanguageCode()
    local locale = Locale.getDefault()
    local language = tostring(locale)  -- Converte o objeto para string completa (ex: "pt_BR")
    local langCode = string.sub(language, 1, 2)  -- Extrai os primeiros dois caracteres
    return langCode
end

-- obter resultado
function getRecognitionResult(reqId, attempt)
    if resultFound or attempt > 30 then  -- Verifica se o resultado já foi encontrado ou se o limite de tentativas foi atingido
        if attempt > 30 then
            print("Tempo limite excedido")
        end
        return
    end

    Http.post(result_url, {id = reqId}, {}, function(status, body)
        if status == 200 then
            local result = json.decode(body)
            if result.status == "ok" then
                resultFound = true  -- Resultado encontrado, define a variável como true
                print(result.text)
                return  -- Sai da função e não agenda novas verificações
            elseif result.status == "notready" then
                task(3000, function()  -- Aguardar 5 segundos para a próxima tentativa
                    getRecognitionResult(reqId, attempt + 1)
                end)
            else
                print("Erro ao obter o resultado: " .. result.status)
            end
        else
            print("Erro na requisição: " .. status)
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
                resultFound = false  -- Redefine a variável para permitir novas verificações
                -- Chama a função para começar a verificação do resultado
                getRecognitionResult(responseJson.id, 1)
            else
                print("Erro ao fazer upload da imagem: " .. responseJson.status)
            end
        else
            print("Erro ao fazer upload da imagem: " .. status)
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
  -- Definir o caminho da pasta baseado na escolha do usuário
  local directoryPath = focus == 1 and "/sdcard/bemyeyes/obj" or "/sdcard/bemyeyes/prints"
  
  ensureDirectoryExists(directoryPath)
  
  local imageName = generateImageName()
  service.copy(imageName)
  local imagePath = directoryPath .. "/" .. imageName

  local screenCaptureFunc = function(bmp)
      bmp.compress(Bitmap.CompressFormat.PNG, 90, FileOutputStream(File(imagePath)))
      this.speak("Processando imagem, aguarde.")
      task(300, function()
          local fl = io.open(imagePath, "rb")
          local tfl = fl:read("*a")
          fl:close()
          uploadImage(crypt.base64encode(tfl), getLanguageCode(), true)
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
    local t = {"Reconhecimento do item em Foco", "Reconhecimento de toda a tela"}
    local dlg = LuaDialog().setItems(t).show()
    dlg.onItemClick = function(l, v, p, i)
        dlg.dismiss()
        captureAndProcessImage(i)
    end
end

-- Chamar o diálogo para permitir que o usuário escolha
showOptionsDialog()