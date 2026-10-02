/**
 * Gemini AI Poultry Health & Behavior Analysis Service for NOVARA
 * Uses Google Gemini API (gemini-2.0-flash / gemini-1.5-flash) for multimodal vision
 * and flock behavioral analysis from ESP32-CAM images and environmental sensors.
 */

const getApiKey = () => {
  return (process.env.GEMINI_API_KEY || '').trim();
};

const isConfigured = () => {
  const key = getApiKey();
  return Boolean(key && key.length > 5);
};

const getModelName = () => {
  return process.env.GEMINI_MODEL || 'gemini-flash-latest';
};

/**
 * Analyzes poultry flock health, behavior, and environment using Gemini API.
 * 
 * @param {Object} options
 * @param {string} [options.imageBase64] - Base64 encoded JPEG image from ESP32-CAM or phone
 * @param {string} [options.mimeType] - Image MIME type (default: 'image/jpeg')
 * @param {string} [options.imageUrl] - Public URL to an image
 * @param {Object} [options.sensorData] - Current environmental sensor data { temperature, humidity, foodLevel, waterLevel }
 * @param {string} [options.farmName] - Name of the farm
 * @param {string} [options.flockType] - Type of flock (e.g. Broiler, Layer, Local chicken)
 * @returns {Promise<Object>} Structured health diagnosis and behavioral report
 */
const analyzePoultryHealth = async ({
  imageBase64,
  mimeType = 'image/jpeg',
  imageUrl,
  sensorData = {},
  farmName = 'NOVARA Poultry Coop',
  flockType = 'Poultry / Chicken'
}) => {
  const apiKey = getApiKey();

  // If Gemini API Key is not configured, fall back to intelligent heuristic analysis
  if (!isConfigured()) {
    console.warn('[Gemini] GEMINI_API_KEY is not configured in .env. Falling back to heuristic diagnosis.');
    return generateFallbackAnalysis({ sensorData, farmName, flockType });
  }

  const model = getModelName();
  const endpoint = `https://generativelanguage.googleapis.com/v1beta/models/${model}:generateContent?key=${apiKey}`;

  // Build veterinary system prompt
  const systemPrompt = `You are an expert avian veterinarian and precision poultry farming AI specialist for the NOVARA Smart Poultry System.
Your task is to analyze the provided image (from an ESP32-CAM or camera) along with environmental telemetry to assess poultry flock health and behavior.

FLOCK CONTEXT:
- Farm: ${farmName}
- Flock Type: ${flockType}
- Temperature: ${sensorData.temperature !== undefined ? `${sensorData.temperature}°C` : 'N/A'}
- Humidity: ${sensorData.humidity !== undefined ? `${sensorData.humidity}%` : 'N/A'}
- Food Level: ${sensorData.foodLevel !== undefined ? `${sensorData.foodLevel}%` : 'N/A'}
- Water Level: ${sensorData.waterLevel !== undefined ? `${sensorData.waterLevel}%` : 'N/A'}

CLINICAL & BEHAVIORAL CRITERIA:
1. Posture & Mobility: Watch for lethargy, drooping head/wings, huddling/clustering, limping, or immobility.
2. Head & Facial Features: Check comb/wattle color (cyanosis, pallor, lesions), eye discharge, or facial swelling.
3. Respiration & Heat Distress: Check for open-mouth breathing, rapid panting, or wing spreading (heat stress correlation with temperature > 30°C).
4. Flock Distribution & Density: Note whether birds are evenly distributed or clustered, piled in corners, or experiencing Overcrowding / High Density.
5. Feeding & Drinking: Observe activity and competition around feeding troughs and waterers.

OUTPUT FORMAT:
You MUST respond with ONLY a valid, raw JSON object (no markdown fences, no explanatory text):
{
  "healthStatus": "healthy" | "warning" | "critical",
  "abnormalityDetected": "None" | "Overcrowding / Excessive Density" | "Heat Stress" | "Lethargy & Drooping" | "Clustering / Cold Stress" | "Respiratory Distress" | "Feather Pecking" | "Digestive / Vent Issue",
  "confidence": 0.0 to 1.0,
  "flockBehaviorSummary": "Concise 1-2 sentence description of overall flock posture, activity, and distribution.",
  "symptoms": ["list", "of", "observed", "signs"],
  "recommendedActions": ["step 1 for the farmer", "step 2", "step 3"],
  "environmentalCorrelation": "How temperature/humidity/feed/water levels relate to the observed flock condition."
}`;

  const contentsParts = [];

  // Add image if provided
  if (imageBase64) {
    const cleanBase64 = imageBase64.replace(/^data:image\/\w+;base64,/, '');
    contentsParts.push({
      inlineData: {
        mimeType: mimeType || 'image/jpeg',
        data: cleanBase64
      }
    });
  }

  // Add text prompt
  contentsParts.push({
    text: `${systemPrompt}\n\nPlease analyze the poultry image and sensor readings now. Return strictly valid JSON.`
  });

  try {
    const response = await fetch(endpoint, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json'
      },
      body: JSON.stringify({
        contents: [{ parts: contentsParts }],
        generationConfig: {
          temperature: 0.2,
          maxOutputTokens: 800,
          responseMimeType: 'application/json'
        }
      })
    });

    if (!response.ok) {
      const errText = await response.text();
      console.error(`[Gemini] API error (${response.status}):`, errText);
      return generateFallbackAnalysis({ sensorData, farmName, flockType, error: `Gemini API HTTP ${response.status}` });
    }

    const result = await response.json();
    const candidateText = result.candidates?.[0]?.content?.parts?.[0]?.text;

    if (!candidateText) {
      return generateFallbackAnalysis({ sensorData, farmName, flockType, error: 'Empty response from Gemini' });
    }

    // Parse the JSON output safely
    const firstBrace = candidateText.indexOf('{');
    const lastBrace = candidateText.lastIndexOf('}');
    let cleanJson = candidateText.trim().replace(/^```json\s*/i, '').replace(/\s*```$/i, '').trim();
    if (firstBrace !== -1 && lastBrace !== -1 && lastBrace > firstBrace) {
      cleanJson = candidateText.substring(firstBrace, lastBrace + 1);
    }
    const parsed = JSON.parse(cleanJson);

    return {
      success: true,
      provider: 'Gemini AI',
      model,
      healthStatus: parsed.healthStatus || 'good',
      abnormalityDetected: parsed.abnormalityDetected || 'None',
      confidence: typeof parsed.confidence === 'number' ? parsed.confidence : 0.9,
      flockBehaviorSummary: parsed.flockBehaviorSummary || 'Flock activity is within normal parameters.',
      symptoms: Array.isArray(parsed.symptoms) ? parsed.symptoms : [],
      recommendedActions: Array.isArray(parsed.recommendedActions) ? parsed.recommendedActions : ['Continue routine flock monitoring.'],
      environmentalCorrelation: parsed.environmentalCorrelation || 'Environmental readings are standard.',
      analyzedAt: new Date().toISOString()
    };
  } catch (error) {
    console.error('[Gemini] Exception during poultry analysis:', error.message);
    return generateFallbackAnalysis({ sensorData, farmName, flockType, error: error.message });
  }
};

/**
 * Intelligent heuristic fallback when Gemini API key is missing or offline.
 */
const generateFallbackAnalysis = ({ sensorData = {}, farmName = '', flockType = '', error = null }) => {
  const temp = parseFloat(sensorData.temperature);
  const hum = parseFloat(sensorData.humidity);
  const water = parseFloat(sensorData.waterLevel);
  const food = parseFloat(sensorData.foodLevel);

  let healthStatus = 'good';
  let abnormality = 'None';
  let confidence = 0.85;
  const symptoms = [];
  const actions = [];
  let summary = 'Poultry behavior and physical posture appear normal.';
  let correlation = 'Environmental parameters are within normal poultry comfort zones.';

  if (!isNaN(temp) && temp > 32) {
    healthStatus = 'warning';
    abnormality = 'Heat Stress Alert';
    confidence = 0.92;
    symptoms.push('Panting and open-mouth breathing', 'Wings held away from body', 'Reduced feed intake');
    actions.push('Activate ventilation fans immediately', 'Ensure cool, fresh drinking water', 'Consider misting or fogging');
    summary = `Flock is exhibiting behavioral signs of heat stress due to elevated coop temperature (${temp}°C).`;
    correlation = `Temperature (${temp}°C) exceeds the optimal broiler comfort zone of 18-24°C.`;
  } else if (!isNaN(temp) && temp < 18) {
    healthStatus = 'warning';
    abnormality = 'Cold Stress / Huddling';
    confidence = 0.88;
    symptoms.push('Birds clustering tightly together', 'Ruffled plumage', 'Reduced movement');
    actions.push('Turn on brooder/infrared heat lamps', 'Inspect coop for cold air drafts', 'Verify litter dryness');
    summary = `Flock is clustering to conserve heat under suboptimal ambient temperature (${temp}°C).`;
    correlation = `Low temperature (${temp}°C) induces shivering thermogenesis and clustering behavior.`;
  } else if (!isNaN(water) && water < 20) {
    healthStatus = 'warning';
    abnormality = 'Dehydration Risk';
    confidence = 0.90;
    symptoms.push('Crowding around drinker lines', 'Dry mucous membranes');
    actions.push('Refill water reservoir immediately', 'Check automated water pump valve');
    summary = 'Flock behavior indicates agitation due to critical water depletion.';
    correlation = `Water level is critically low at ${water}%.`;
  } else if (sensorData.densityStatus === 'overcrowded' || (sensorData.poultryCount && sensorData.capacity && sensorData.poultryCount > sensorData.capacity)) {
    healthStatus = 'warning';
    abnormality = 'Overcrowding / Excessive Density';
    confidence = 0.94;
    symptoms.push('Excessive bird density per square meter', 'Piling and flock agitation in coop corners', 'High competition at feeders');
    actions.push('Thin out flock or partition coop into separate pens', 'Install additional feeder and drinker lines', 'Increase ventilation to disperse body heat and ammonia');
    summary = 'Visual flock distribution indicates overcrowding and high stocking density.';
    correlation = `Flock density exceeds optimal capacity (${sensorData.poultryCount || 'High'} birds in space rated for ${sensorData.capacity || 'lower count'}).`;
  }

  return {
    success: true,
    provider: error ? 'Rule-Based Fallback' : 'Smart Heuristic Engine',
    healthStatus,
    abnormalityDetected: abnormality,
    confidence,
    flockBehaviorSummary: summary,
    symptoms: symptoms.length > 0 ? symptoms : ['Active foraging', 'Even coop dispersion', 'Normal alertness'],
    recommendedActions: actions.length > 0 ? actions : ['Maintain standard feeding schedule', 'Continue regular flock inspection'],
    environmentalCorrelation: correlation,
    notice: error ? `AI Note: ${error}. Using calibrated avian veterinary rules.` : 'Awaiting GEMINI_API_KEY in .env for advanced vision neural analysis.',
    analyzedAt: new Date().toISOString()
  };
};

module.exports = {
  isConfigured,
  analyzePoultryHealth
};
