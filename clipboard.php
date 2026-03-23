<?php
/**
 * Clipboard Markdown Editor
 *
 * Edit clipboard.md file with a simple textarea editor.
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
                <textarea name="content" id="editor"><?php echo htmlspecialchars($content); ?></textarea>
            </div>

            <div class="button-group">
                <button type="submit">Save</button>
                <button type="button" onclick="location.reload()">Reload</button>
            </div>
        </form>
    </div>

    <script>
        // Simple autofocus on the textarea
        document.addEventListener('DOMContentLoaded', function() {
            document.getElementById('editor').focus();
        });
    </script>
</body>
</html>
