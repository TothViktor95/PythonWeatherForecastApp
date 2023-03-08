from flask import Flask, jsonify, render_template
import requests
import prometheus_client

app = Flask(__name__)

weather_requests = prometheus_client.Counter('weather_requests', 'Number of requests to the weather endpoint')
request_latency = prometheus_client.Histogram('request_latency_seconds', 'Time spent handling request')
uptime = prometheus_client.Gauge('uptime', 'Time since the application started')

@app.route('/')
def index():
    return render_template('index.html')


@app.route('/weather/<city>')
def get_weather(city):
    weather_requests.inc()
    with request_latency.time():
        api_key = 'bedf2102d366dfa5eb4d813db2a059d4'
        url = f'http://api.openweathermap.org/data/2.5/weather?q={city}&appid={api_key}'
        response = requests.get(url)
        data = response.json()
    return jsonify(data)


@app.route('/metrics')
def metrics():
    return prometheus_client.generate_latest()


if __name__ == '__main__':
    uptime.set_to_current_time()
    app.run(debug=True, host='0.0.0.0')



