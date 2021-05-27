from flask import Flask

app = Flask(__name__)

@app.route("/")
def index():
    return'''
        <head><meta charset=utf-8></head>
        <title>Flask testing connection</title>
        <h1>Ура, все работает!</h1>
        <p>Если на экран выведено это сообщение, значит все работает.</p>
        '''

    return app

if __name__ == "__main__":
    app = create_app()
    app.run()
else:
    application = app
