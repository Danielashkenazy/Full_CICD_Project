import flask

app = flask.Flask(__name__)


@app.route('/', methods=['GET'])
def main():
    return "Hello, Devops!"


@app.route('/echo', methods=['POST'])
def echo():
    data = flask.request.get_json()
    return flask.jsonify(data)


if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)
