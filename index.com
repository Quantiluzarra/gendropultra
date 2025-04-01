<!DOCTYPE html>
<html lang="ru">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Генератор изображений по тексту</title>
    <style>
        body {
            font-family: 'Arial', sans-serif;
            background: linear-gradient(135deg, #1e1e1e, #2d2d2d);
            color: #ffffff;
            margin: 0;
            padding: 0;
            display: flex;
            justify-content: center;
            align-items: center;
            min-height: 100vh;
            flex-direction: column;
            overflow-x: hidden;
            transition: background 0.5s ease, color 0.5s ease;
        }

        /* Светлая тема */
        body.light {
            background: linear-gradient(135deg, #f0f0f0, #ffffff);
            color: #000000;
        }

        .container {
            background-color: rgba(45, 45, 45, 0.9);
            padding: 20px;
            border-radius: 10px;
            box-shadow: 0 4px 15px rgba(0, 0, 0, 0.2);
            width: 90%;
            max-width: 500px;
            text-align: center;
            position: relative;
            transition: background-color 0.5s ease;
        }

        body.light .container {
            background-color: rgba(255, 255, 255, 0.9);
        }

        h1 {
            font-size: 24px;
            margin-bottom: 20px;
            color: #007BFF;
            animation: slideIn 0.5s ease;
        }

        @keyframes slideIn {
            from { transform: translateY(-20px); opacity: 0; }
            to { transform: translateY(0); opacity: 1; }
        }

        #inputText {
            width: calc(100% - 40px);
            padding: 10px;
            border: 1px solid #444;
            border-radius: 5px;
            background-color: #3d3d3d;
            color: #ffffff;
            margin-bottom: 10px;
            font-size: 16px;
            transition: border-color 0.3s ease, transform 0.2s ease;
        }

        #inputText:focus {
            border-color: #007BFF;
            transform: scale(1.02);
            outline: none;
        }

        body.light #inputText {
            background-color: #ffffff;
            color: #000000;
            border: 1px solid #ccc;
        }

        #aspectRatio {
            padding: 8px;
            border-radius: 5px;
            background-color: #3d3d3d;
            color: #ffffff;
            border: 1px solid #444;
            margin-bottom: 10px;
            transition: background-color 0.3s ease;
        }

        body.light #aspectRatio {
            background-color: #ffffff;
            color: #000000;
            border: 1px solid #ccc;
        }

        #generateButton, #downloadButton, #regenerateButton {
            padding: 10px 20px;
            border: none;
            border-radius: 5px;
            cursor: pointer;
            margin: 5px;
            transition: transform 0.2s ease, background-color 0.3s ease;
            font-size: 16px;
        }

        #generateButton {
            background-color: #007BFF;
            color: white;
        }

        #generateButton:hover {
            background-color: #0056b3;
            transform: scale(1.05);
        }

        #downloadButton {
            background-color: #28a745;
            color: white;
        }

        #downloadButton:hover {
            background-color: #218838;
            transform: scale(1.05);
        }

        #regenerateButton {
            background-color: #dc3545;
            color: white;
        }

        #regenerateButton:hover {
            background-color: #c82333;
            transform: scale(1.05);
        }

        button:active {
            transform: scale(0.95);
        }

        #loading {
            display: none;
            font-size: 18px;
            margin-bottom: 20px;
            color: #28a745;
            align-items: center;
            justify-content: center;
        }

        .spinner {
            border: 4px solid rgba(255, 255, 255, 0.3);
            border-radius: 50%;
            border-top: 4px solid #ffffff;
            width: 24px;
            height: 24px;
            animation: spin 1s linear infinite;
            display: inline-block;
            margin-right: 10px;
        }

        body.light .spinner {
            border-top: 4px solid #28a745;
            border: 4px solid rgba(40, 167, 69, 0.3);
        }

        @keyframes spin {
            0% { transform: rotate(0deg); }
            100% { transform: rotate(360deg); }
        }

        #progressBar {
            width: 100%;
            height: 10px;
            background-color: #3d3d3d;
            border-radius: 5px;
            margin-bottom: 20px;
            overflow: hidden;
            display: none;
        }

        body.light #progressBar {
            background-color: #e0e0e0;
        }

        #progressBarFill {
            width: 0%;
            height: 100%;
            background-color: #28a745;
            transition: width 0.5s ease-in-out;
        }

        #imageContainer {
            display: none;
            margin-bottom: 20px;
        }

        #generatedImage {
            max-width: 100%;
            border-radius: 5px;
            animation: fadeInScale 1s ease;
            box-shadow: 0 4px 10px rgba(0, 0, 0, 0.3);
        }

        @keyframes fadeInScale {
            from { opacity: 0; transform: scale(0.9); }
            to { opacity: 1; transform: scale(1); }
        }

        #settingsButton {
            position: absolute;
            top: 10px;
            right: 10px;
            background: none;
            border: none;
            font-size: 24px;
            cursor: pointer;
            color: #ffffff;
            transition: transform 0.2s ease;
        }

        body.light #settingsButton {
            color: #000000;
        }

        #settingsButton:hover {
            transform: rotate(90deg);
        }

        #settingsPanel {
            position: fixed;
            top: 0;
            right: -300px;
            width: 250px;
            height: 100%;
            background-color: rgba(45, 45, 45, 0.95);
            padding: 20px;
            box-shadow: -2px 0 10px rgba(0, 0, 0, 0.5);
            transition: right 0.3s ease;
            z-index: 1000;
        }

        body.light #settingsPanel {
            background-color: rgba(255, 255, 255, 0.95);
            color: #000000;
        }

        #settingsPanel.open {
            right: 0;
        }

        .footer {
            position: fixed;
            bottom: 10px;
            right: 10px;
            font-size: 12px;
            color: #888;
        }

        body.light .footer {
            color: #666;
        }

        .footer a {
            color: #007BFF;
            text-decoration: none;
        }

        .footer a:hover {
            text-decoration: underline;
        }

        /* Адаптивность */
        @media (max-width: 600px) {
            .container {
                width: 95%;
                padding: 15px;
            }
            h1 {
                font-size: 20px;
            }
            #inputText, #aspectRatio, #generateButton, #downloadButton, #regenerateButton {
                font-size: 14px;
            }
            #settingsPanel {
                width: 100%;
                right: -100%;
            }
            #settingsPanel.open {
                right: 0;
            }
        }
    </style>
</head>
<body>
    <div class="container">
        <h1>Генератор изображений по тексту</h1>
        <input type="text" id="inputText" placeholder="Введите описание изображения...">
        <select id="aspectRatio">
            <option value="1:1">1:1 (Квадрат)</option>
            <option value="16:9">16:9 (Широкий)</option>
            <option value="4:3">4:3 (Стандарт)</option>
        </select>
        <button id="generateButton">Сгенерировать</button>
        <div id="loading">
            <div class="spinner"></div>
            Генерация изображения...
        </div>
        <div id="progressBar">
            <div id="progressBarFill"></div>
        </div>
        <div id="imageContainer">
            <img id="generatedImage" src="" alt="Сгенерированное изображение">
            <div>
                <button id="downloadButton">Скачать</button>
                <button id="regenerateButton">Сгенерировать другое</button>
            </div>
        </div>
        <button id="settingsButton">⚙️</button>
    </div>

    <div id="settingsPanel">
        <h2>Настройки</h2>
        <label>
            <input type="checkbox" id="themeToggle"> Светлая тема
        </label>
    </div>

    <div class="footer">
        Разработано: <a href="https://t.me/+08Jc-04X_M5mMDQy" target="_blank">AjinCry.Cn X</a>
    </div>

    <script>
        // Функция для генерации изображения по тексту с учетом соотношения сторон
        async function generateImageFromText(text, aspectRatio) {
            try {
                const totalSteps = 10;
                let progress = 0;

                const updateProgress = () => {
                    progress += 1;
                    const percent = (progress / totalSteps) * 100;
                    document.getElementById('progressBarFill').style.width = `${percent}%`;
                };

                const [widthRatio, heightRatio] = aspectRatio.split(':').map(Number);
                const baseWidth = 400;
                const canvasWidth = baseWidth;
                const canvasHeight = (baseWidth * heightRatio) / widthRatio;

                const canvas = document.createElement('canvas');
                canvas.width = canvasWidth;
                canvas.height = canvasHeight;
                const ctx = canvas.getContext('2d');

                ctx.fillStyle = document.body.classList.contains('light') ? '#ffffff' : '#3d3d3d';
                ctx.fillRect(0, 0, canvas.width, canvas.height);

                ctx.fillStyle = document.body.classList.contains('light') ? '#000000' : '#ffffff';
                ctx.font = '20px Arial';
                ctx.textAlign = 'center';
                ctx.fillText(text, canvas.width / 2, canvas.height / 2);

                for (let i = 0; i < totalSteps; i++) {
                    await new Promise(resolve => setTimeout(resolve, 300));
                    updateProgress();
                }

                return canvas.toDataURL('image/png');
            } catch (error) {
                console.error("Ошибка генерации:", error);
                alert("Не удалось сгенерировать изображение.");
                return null;
            }
        }

        // Функция для скачивания изображения
        function downloadImage(imageUrl, filename) {
            const link = document.createElement('a');
            link.href = imageUrl;
            link.download = filename;
            link.click();
        }

        // Обработка кнопки "Сгенерировать"
        document.getElementById('generateButton').addEventListener('click', async () => {
            const inputText = document.getElementById('inputText').value.trim();
            const aspectRatio = document.getElementById('aspectRatio').value;

            if (!inputText) {
                alert('Пожалуйста, введите описание изображения.');
                return;
            }

            document.getElementById('loading').style.display = 'flex';
            document.getElementById('progressBar').style.display = 'block';
            document.getElementById('imageContainer').style.display = 'none';

            const imageUrl = await generateImageFromText(inputText, aspectRatio);

            document.getElementById('loading').style.display = 'none';
            document.getElementById('progressBar').style.display = 'none';
            if (imageUrl) {
                document.getElementById('generatedImage').src = imageUrl;
                document.getElementById('imageContainer').style.display = 'block';

                document.getElementById('downloadButton').onclick = () => {
                    downloadImage(imageUrl, 'generated-image.png');
                };

                document.getElementById('regenerateButton').onclick = async () => {
                    document.getElementById('loading').style.display = 'flex';
                    document.getElementById('progressBar').style.display = 'block';
                    document.getElementById('imageContainer').style.display = 'none';

                    const newImageUrl = await generateImageFromText(inputText, aspectRatio);
                    document.getElementById('loading').style.display = 'none';
                    document.getElementById('progressBar').style.display = 'none';
                    if (newImageUrl) {
                        document.getElementById('generatedImage').src = newImageUrl;
                        document.getElementById('imageContainer').style.display = 'block';
                    }
                };
            }
        });

        // Настройки
        const settingsButton = document.getElementById('settingsButton');
        const settingsPanel = document.getElementById('settingsPanel');
        const themeToggle = document.getElementById('themeToggle');

        settingsButton.addEventListener('click', () => {
            settingsPanel.classList.toggle('open');
        });

        themeToggle.addEventListener('change', () => {
            if (themeToggle.checked) {
                document.body.classList.add('light');
                localStorage.setItem('theme', 'light');
            } else {
                document.body.classList.remove('light');
                localStorage.setItem('theme', 'dark');
            }
        });

        // Загрузка сохраненной темы
        const savedTheme = localStorage.getItem('theme');
        if (savedTheme === 'light') {
            document.body.classList.add('light');
            themeToggle.checked = true;
        }
    </script>
</body>
</html>
