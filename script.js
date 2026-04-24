const cityInput = document.getElementById('cityInput');
const searchBtn = document.getElementById('searchBtn');
const initialState = document.getElementById('initialState');
const statusMessage = document.getElementById('statusMessage');
const errorMessage = document.getElementById('errorMessage');
const errorText = document.getElementById('errorText');
const weatherResult = document.getElementById('weatherResult');

const DEGREE = '\u00B0';

searchBtn.addEventListener('click', fetchWeather);
cityInput.addEventListener('keypress', (e) => {
    if (e.key === 'Enter') fetchWeather();
});

async function fetchWeather() {
    const city = cityInput.value.trim();

    if (!city) {
        showError('Please enter a city name');
        return;
    }

    showLoading();

    try {
        const response = await fetch(`/weather?city=${encodeURIComponent(city)}`);

        if (!response.ok) {
            const errorData = await response.json();
            throw new Error(errorData.error || 'City not found');
        }

        const data = await response.json();
        displayWeather(data);
    } catch (error) {
        showError(error.message);
    }
}

function displayWeather(data) {
    initialState.classList.add('hidden');
    statusMessage.classList.add('hidden');
    errorMessage.classList.add('hidden');
    weatherResult.classList.remove('hidden');

    document.getElementById('cityName').textContent = data.city;
    document.getElementById('countryCode').textContent = data.country;
    document.getElementById('temperature').textContent = Math.round(data.temperature) + DEGREE + 'C';
    document.getElementById('description').textContent = data.description;
    document.getElementById('feelsLike').textContent = Math.round(data.feelsLike) + DEGREE + 'C';
    document.getElementById('humidity').textContent = data.humidity + '%';
    document.getElementById('windSpeed').textContent = data.windSpeed + ' km/h';
    document.getElementById('pressure').textContent = data.pressure + ' hPa';
    document.getElementById('visibility').textContent = data.visibility + ' km';
    document.getElementById('cloudiness').textContent = data.cloudiness + '%';
    document.getElementById('sunrise').textContent = data.sunrise;
    document.getElementById('sunset').textContent = data.sunset;

    const weatherIcon = document.getElementById('weatherIcon');
    weatherIcon.className = 'fas ' + getWeatherIcon(data.weatherCode);
}

function getWeatherIcon(code) {
    const iconMap = {
        200: 'fa-bolt',
        300: 'fa-cloud-rain',
        500: 'fa-cloud-showers-heavy',
        600: 'fa-snowflake',
        700: 'fa-smog',
        800: 'fa-sun',
        801: 'fa-cloud-sun',
        802: 'fa-cloud',
        803: 'fa-cloud',
        804: 'fa-cloud'
    };

    for (const [key, icon] of Object.entries(iconMap)) {
        if (code >= parseInt(key) && code < parseInt(key) + 100) {
            return icon;
        }
    }
    return 'fa-sun';
}

function showLoading() {
    initialState.classList.add('hidden');
    weatherResult.classList.add('hidden');
    errorMessage.classList.add('hidden');
    statusMessage.classList.remove('hidden');
    statusMessage.innerHTML = '<i class="fas fa-spinner fa-pulse"></i><span>Loading...</span>';
}

function showError(message) {
    initialState.classList.add('hidden');
    weatherResult.classList.add('hidden');
    statusMessage.classList.add('hidden');
    errorMessage.classList.remove('hidden');
    errorText.textContent = message;
}