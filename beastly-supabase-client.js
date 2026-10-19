// beastly-supabase-client.js
// Drop-in client for the upgraded Beastly Point Tap front-end.
// Requires: window.SUPABASE_URL and window.SUPABASE_ANON_KEY set before this script.
// Never put the service_role key here.

(function () {
  if (!window.SUPABASE_URL || !window.SUPABASE_ANON_KEY) {
    console.warn('[Beastly] Missing SUPABASE_URL or SUPABASE_ANON_KEY. Cloud save disabled.');
    return;
  }

  const { createClient } = window.supabase || {};
  if (!createClient) {
    console.warn('[Beastly] @supabase/supabase-js not loaded. Include the CDN script first.');
    return;
  }

  const supabase = createClient(window.SUPABASE_URL, window.SUPABASE_ANON_KEY, {
    auth: { persistSession: true, autoRefreshToken: true },
  });

  window.beastlySupabase = {
    client: supabase,

    async ensureProfile() {
      const { data: { user } } = await supabase.auth.getUser();
      if (!user) throw new Error('Not authenticated');
      const { data, error } = await supabase.rpc('ensure_profile');
      if (error) throw error;
      return data;
    },

    async loadProgress() {
      const { data: { user } } = await supabase.auth.getUser();
      if (!user) return null;
      const { data, error } = await supabase
        .from('profiles')
        .select('*')
        .eq('id', user.id)
        .maybeSingle();
      if (error) throw error;
      return data;
    },

    async saveProgress(miner) {
      const { data: { user } } = await supabase.auth.getUser();
      if (!user) throw new Error('Not authenticated');
      const payload = {
        id: user.id,
        display_name: miner.display_name,
        points: miner.points,
        total_mined: miner.total_mined,
        tap_power: miner.tap_power,
        passive_rate: miner.passive_rate,
        stamina_capacity: miner.stamina_capacity,
        stamina: miner.stamina,
        last_action: new Date(miner.last_action || Date.now()).toISOString(),
        last_claim: new Date(miner.last_claim || Date.now()).toISOString(),
        boost_until: miner.boost_until || null,
        frenzy_until: miner.frenzy_until || null,
        wallet: miner.wallet || null,
      };
      const { error } = await supabase.from('profiles').upsert(payload);
      if (error) throw error;
    },

    async requestChallenge(wallet) {
      const { data, error } = await supabase.functions.invoke('wallet-auth', {
        body: { action: 'challenge', wallet },
      });
      if (error) throw error;
      return data;
    },

    async verifySignature(wallet, nonce, signatureBase64) {
      const { data, error } = await supabase.functions.invoke('wallet-auth', {
        body: { action: 'verify', wallet, nonce, signature: signatureBase64 },
      });
      if (error) throw error;
      return data;
    },
  };
})();
