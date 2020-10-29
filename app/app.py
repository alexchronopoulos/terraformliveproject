from flask import Flask
app = Flask(__name__)

version = open('./version.txt').read()

@app.route('/')
def hello():
    return f"Hello World! {version}"

if __name__ == '__main__':
    app.run(host='0.0.0.0')