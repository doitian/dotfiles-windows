<?php
/**
 * Clipboard Markdown Editor
 *
 * Edit clipboard.md file with a lazy-loaded markdown editor.
 * Falls back to plain textarea if lazy loading fails.
 */

$file = __DIR__ . '/clipboard.md';

// Handle form submission
if ($_SERVER['REQUEST_METHOD'] === 'POST' && isset($_POST['content'])) {
    file_put_contents($file, $_POST['content']);
    $message = 'File saved successfully!';
}

// Read current content
$content = file_exists($file) ? file_get_contents($file) : '';
?>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Clipboard Editor</title>
    <style>
        * {
            box-sizing: border-box;
        }
        body {
            font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, "Helvetica Neue", Arial, sans-serif;
            margin: 0;
            padding: 20px;
            background-color: #f5f5f5;
        }
        .container {
            max-width: 1200px;
            margin: 0 auto;
            background-color: white;
            padding: 20px;
            border-radius: 8px;
            box-shadow: 0 2px 4px rgba(0,0,0,0.1);
        }
        h1 {
            margin-top: 0;
            color: #333;
        }
        .message {
            padding: 10px;
            margin-bottom: 15px;
            background-color: #d4edda;
            color: #155724;
            border: 1px solid #c3e6cb;
            border-radius: 4px;
        }
        .editor-container {
            margin-bottom: 15px;
        }
        #editor {
            width: 100%;
            min-height: 400px;
            padding: 10px;
            border: 1px solid #ddd;
            border-radius: 4px;
            font-family: 'Courier New', Courier, monospace;
            font-size: 14px;
            resize: vertical;
        }
        .button-group {
            display: flex;
            gap: 10px;
        }
        button {
            padding: 10px 20px;
            background-color: #007bff;
            color: white;
            border: none;
            border-radius: 4px;
            cursor: pointer;
            font-size: 14px;
        }
        button:hover {
            background-color: #0056b3;
        }
        .loading {
            text-align: center;
            padding: 10px;
            color: #666;
        }
        /* EasyMDE will override these styles when loaded */
        .CodeMirror {
            min-height: 400px;
        }
    </style>
</head>
<body>
    <div class="container">
        <h1>Clipboard Editor</h1>

        <?php if (isset($message)): ?>
            <div class="message"><?php echo htmlspecialchars($message); ?></div>
        <?php endif; ?>

        <form method="POST" id="editorForm">
            <div class="editor-container">
                <div id="loading" class="loading">Loading markdown editor...</div>
                <textarea name="content" id="editor" style="display: none;"><?php echo htmlspecialchars($content); ?></textarea>
            </div>

            <div class="button-group">
                <button type="submit">Save</button>
                <button type="button" onclick="location.reload()">Reload</button>
            </div>
        </form>
    </div>

    <script>
        // Configuration
        const EDITOR_CDN = {
            fontawesome: '//cdn.jsdelivr.net/npm/font-awesome@4.7.0/css/font-awesome.min.css',
            css: '//cdn.jsdelivr.net/npm/easymde@2.18.0/dist/easymde.min.css',
            js: '//cdn.jsdelivr.net/npm/easymde@2.18.0/dist/easymde.min.js'
        };

        const LOAD_TIMEOUT = 5000; // 5 seconds timeout
        let editorInstance = null;
        let loadingFailed = false;

        // Fallback to plain textarea
        function fallbackToTextarea() {
            if (loadingFailed) return;
            loadingFailed = true;

            console.warn('Falling back to plain textarea');
            const loading = document.getElementById('loading');
            const textarea = document.getElementById('editor');

            loading.textContent = 'Using plain text editor (markdown editor failed to load)';
            loading.style.color = '#856404';
            loading.style.backgroundColor = '#fff3cd';
            loading.style.padding = '10px';
            loading.style.borderRadius = '4px';
            loading.style.marginBottom = '10px';

            textarea.style.display = 'block';
        }

        // Load CSS dynamically
        function loadCSS(url) {
            return new Promise((resolve, reject) => {
                const link = document.createElement('link');
                link.rel = 'stylesheet';
                link.href = url;
                link.onload = resolve;
                link.onerror = reject;
                document.head.appendChild(link);
            });
        }

        // Load JavaScript dynamically
        function loadJS(url) {
            return new Promise((resolve, reject) => {
                const script = document.createElement('script');
                script.src = url;
                script.onload = resolve;
                script.onerror = reject;
                document.body.appendChild(script);
            });
        }

        // Initialize markdown editor
        async function initializeEditor() {
            const textarea = document.getElementById('editor');
            const loading = document.getElementById('loading');

            try {
                // Set timeout for loading
                const timeoutPromise = new Promise((_, reject) =>
                    setTimeout(() => reject(new Error('Loading timeout')), LOAD_TIMEOUT)
                );

                // Load FontAwesome, CSS and JS
                await Promise.race([
                    Promise.all([
                        loadCSS(EDITOR_CDN.fontawesome),
                        loadCSS(EDITOR_CDN.css),
                        loadJS(EDITOR_CDN.js)
                    ]),
                    timeoutPromise
                ]);

                // Check if EasyMDE is available
                if (typeof EasyMDE === 'undefined') {
                    throw new Error('EasyMDE not loaded');
                }

                // Initialize EasyMDE
                editorInstance = new EasyMDE({
                    element: textarea,
                    autofocus: true,
                    spellChecker: false,
                    toolbar: [
                        'bold', 'italic', 'heading', '|',
                        'quote', 'unordered-list', 'ordered-list', '|',
                        'link', 'image', '|',
                        'preview', 'side-by-side', 'fullscreen', '|',
                        'guide'
                    ],
                    status: ['lines', 'words', 'cursor'],
                    minHeight: '400px'
                });

                // Hide loading message
                loading.style.display = 'none';

                console.log('Markdown editor loaded successfully');
            } catch (error) {
                console.error('Failed to load markdown editor:', error);
                fallbackToTextarea();
            }
        }

        // Handle form submission
        document.getElementById('editorForm').addEventListener('submit', function(e) {
            if (editorInstance && !loadingFailed) {
                // EasyMDE automatically syncs with textarea, but let's be explicit
                editorInstance.codemirror.save();
            }
        });

        // Initialize editor when page loads
        window.addEventListener('DOMContentLoaded', initializeEditor);
    </script>
</body>
</html>
