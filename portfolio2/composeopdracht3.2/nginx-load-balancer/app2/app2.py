from flask import Flask
app2 = Flask(__name__)

@app2.route('/')
def hello_world():
    return '<h1>Hello from server 2</h1>'

if __name__ == '__main__':
    app2.run(debug=True, host='0.0.0.0')
