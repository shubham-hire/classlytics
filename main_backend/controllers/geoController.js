const { State, City } = require('country-state-city');

exports.getStates = (req, res) => {
    try {
        console.log('Fetching states for India (IN)');
        const states = State.getStatesOfCountry('IN'); 
        console.log(`Found ${states.length} states.`);
        res.status(200).json(states.map(s => ({ name: s.name, isoCode: s.isoCode })));
    } catch (err) {
        console.error('GeoController Error:', err);
        res.status(500).json({ error: err.message });
    }
};

exports.getCities = (req, res) => {
    const { stateCode } = req.params;
    try {
        const cities = City.getCitiesOfState('IN', stateCode);
        res.status(200).json(cities.map(c => ({ name: c.name })));
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
};
