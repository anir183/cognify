import wave
import math
import struct
import os

def generate_wav(filename, duration, frequency_func, volume=0.5):
    sample_rate = 44100
    n_samples = int(sample_rate * duration)
    
    with wave.open(filename, 'w') as wav_file:
        wav_file.setnchannels(1)  # Mono
        wav_file.setsampwidth(2)  # 16-bit
        wav_file.setframerate(sample_rate)
        
        for i in range(n_samples):
            t = i / sample_rate
            freq = frequency_func(t, duration)
            # Generate sine wave
            value = int(volume * 32767.0 * math.sin(2.0 * math.pi * freq * t))
            # Clamp value
            value = max(-32768, min(32767, value))
            data = struct.pack('<h', value)
            wav_file.writeframesraw(data)

# Ensure directory exists
os.makedirs('../assets/sounds', exist_ok=True)

# 1. Laser Shoot (Frequency sweep high to low)
print("Generating laser_shoot.wav...")
generate_wav('../assets/sounds/laser_shoot.wav', 0.2, 
             lambda t, d: 880 - (t/d * 600)) # 880Hz -> 280Hz

# 2. Error (Low buzz/square-ish)
print("Generating error.wav...")
# Simple low sine for error
generate_wav('../assets/sounds/error.wav', 0.3, 
             lambda t, d: 150) # Constant 150Hz

# 3. Level Complete (Major chord arpeggio)
print("Generating level_complete.wav...")
# complex generation by mixing frequencies would be better, but let's do a simple fast climb
def victory_tone(t, d):
    # C major arpeggio equivalent frequencies approx: C4, E4, G4, C5
    if t < d * 0.25: return 261.63 # C4
    if t < d * 0.50: return 329.63 # E4
    if t < d * 0.75: return 392.00 # G4
    return 523.25 # C5

generate_wav('../assets/sounds/level_complete.wav', 0.6, victory_tone)

# 4. UI Click (Short high tick)
print("Generating ui_click.wav...")
generate_wav('../assets/sounds/ui_click.wav', 0.05, 
             lambda t, d: 800) # Short 800Hz blip

print("Done! Placeholder sounds generated in frontend/assets/sounds/")
