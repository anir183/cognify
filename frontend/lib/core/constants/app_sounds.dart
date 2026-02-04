class AppSounds {
  // --- 1. BASIC UI ---
  static const String tapPrimary = 'sounds/ui_tap_primary.wav';     // Warmer, fuller
  static const String tapSecondary = 'sounds/ui_tap_secondary.wav'; // Lighter, thinner
  static const String tapIcon = 'sounds/ui_tap_icon.wav';           // Minimal micro-click
  static const String toggleOn = 'sounds/ui_toggle_on.wav';
  static const String toggleOff = 'sounds/ui_toggle_off.wav';

  // --- 2. FORMS & INPUTS ---
  static const String inputFocus = 'sounds/ui_input_focus.wav';     // Soft digital inhale
  static const String submit = 'sounds/ui_submit.wav';              // Gentle confirmation
  static const String success = 'sounds/ui_success.wav';            // Smooth harmonic rise
  static const String error = 'sounds/ui_error.wav';                // Calm downward tone

  // --- 3. AUTHENTICATION ---
  static const String loginSuccess = 'sounds/ui_login_success.wav'; // Reassuring unlock

  // --- 4. BATTLE MODE ---
  static const String battleSelect = 'sounds/battle_select.wav';    // Energy charge
  static const String battleAttack = 'sounds/battle_attack.wav';    // Clean impact
  static const String battleDamage = 'sounds/battle_damage.wav';    // Muted counter
  static const String battleCombo = 'sounds/battle_combo.wav';      // Rhythmic pulse
  static const String battleBoss = 'sounds/battle_boss.wav';        // Low-freq surge

  // --- 5. ACHIEVEMENTS ---
  static const String unlockCommon = 'sounds/unlock_common.wav';    // Soft chime
  static const String unlockRare = 'sounds/unlock_rare.wav';        // Brighter harmonic
  static const String unlockLegendary = 'sounds/unlock_legendary.wav'; // Swell + release

  // --- 6. SYSTEM ---
  static const String signature = 'sounds/cognify_signature.wav';   // Brand identity

  // --- VOLUME LEGEND (0.0 - 1.0) ---
  static const double volBackground = 0.08; // 5-8%
  static const double volUI = 0.12;         // 8-12%
  static const double volForm = 0.10;       // 6-10%
  static const double volBattle = 0.18;     // 12-18%
  static const double volLegendary = 0.25;  // 20-25%
}

enum SoundType {
  // UI
  tapPrimary,
  tapSecondary,
  tapIcon,
  toggle,
  
  // Forms
  submit,
  success,
  error,
  inputFocus,

  // Auth
  login,

  // Battle
  battleSelect,
  battleAttack, // Projectile launch
  battleHit,    // Damage taken/Screen shake
  battleCombo,
  battleBoss,

  // Unlock
  unlockCommon,
  unlockRare,
  unlockLegendary,

  // Brand
  signature
}
