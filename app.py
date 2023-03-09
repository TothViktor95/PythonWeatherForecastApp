from flask import Flask, jsonify, render_template, request
import requests
import prometheus_client

app = Flask(__name__)

weather_requests = prometheus_client.Counter('weather_requests', 'Number of requests to the weather endpoint')
request_latency = prometheus_client.Histogram('request_latency_seconds', 'Time spent handling request')
uptime = prometheus_client.Gauge('uptime', 'Time since the application started')

@app.route('/')
def index():
    return render_template('index.html')


# @app.route('/weather/<city>')
@app.route('/weather.php')
def get_weather():
    city = request.args.get('city')
    weather_requests.inc()
    with request_latency.time():
        api_key = 'bedf2102d366dfa5eb4d813db2a059d4'
        url = f'http://api.openweathermap.org/data/2.5/weather?q={city}&appid={api_key}'
        response = requests.get(url)
        data = response.json()
    #return jsonify(data)

    # Extract relevant data from response
    weather = data['weather'][0]['description']
    temp = data['main']['temp']
    feels_like = data['main']['feels_like']
    humidity = data['main']['humidity']
    pressure = data['main']['pressure']
        
    # Render UI with weather data
    return render_template('weatherResult.html', city=city, weather=weather, temp=temp, feels_like=feels_like, humidity=humidity, pressure=pressure)





@app.route('/metrics')
def metrics():
    return prometheus_client.generate_latest()


if __name__ == '__main__':
    uptime.set_to_current_time()
    app.run(debug=True, host='0.0.0.0')



