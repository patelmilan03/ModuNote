// ModuNote design tokens — Material 3 / Material You
// Seed: #5B4EFF indigo-violet. Accent: #F59E0B warm amber.

const MN_TOKENS = {
  light: {
    // Surfaces
    bg: '#FEFBFF',
    surface: '#FEFBFF',
    card: '#FFFFFF',
    surfaceContainer: '#F4F0FA',
    surfaceContainerHigh: '#EDE8F5',
    // Brand
    primary: '#5B4EFF',
    primaryContainer: '#E4E0FF',
    onPrimaryContainer: '#1A0F8A',
    // Accent
    accent: '#F59E0B',
    accentOn: '#1C1B2E',
    // Text
    onSurface: '#1C1B2E',
    onSurfaceVariant: '#4A4858',
    onSurfaceMuted: '#6F6C7D',
    // Lines
    outline: 'rgba(28,27,46,0.12)',
    outlineStrong: 'rgba(28,27,46,0.22)',
    // Misc
    pinTint: '#FFF4D6',
    recordRed: '#E5484D',
    chipBg: '#EEEBFF',
    chipText: '#3F2FE0',
    frameBorder: '#CBC9D6',
  },
  dark: {
    bg: '#1C1B2E',
    surface: '#1C1B2E',
    card: '#232238',
    surfaceContainer: '#2A2942',
    surfaceContainerHigh: '#33324E',
    primary: '#B7AFFF',
    primaryContainer: '#3D33C7',
    onPrimaryContainer: '#E4E0FF',
    accent: '#F59E0B',
    accentOn: '#1C1B2E',
    onSurface: '#EDECF5',
    onSurfaceVariant: '#BDBAD0',
    onSurfaceMuted: '#8A8799',
    outline: 'rgba(237,236,245,0.12)',
    outlineStrong: 'rgba(237,236,245,0.22)',
    pinTint: '#3A3320',
    recordRed: '#FF6369',
    chipBg: '#2F2A5E',
    chipText: '#B7AFFF',
    frameBorder: '#0F0E1C',
  },
};

const MN_FONTS = {
  head: '"Plus Jakarta Sans", system-ui, sans-serif',
  body: '"Inter", system-ui, sans-serif',
};

Object.assign(window, { MN_TOKENS, MN_FONTS });
