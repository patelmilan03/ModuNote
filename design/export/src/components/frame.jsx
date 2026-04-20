// ModuNote phone frame — Android-ish, 412x892, themed.
// Render children as a full-height column. No top app bar baked in — each screen owns its own.

function MNPhone({ children, theme = 'light', label }) {
  const t = MN_TOKENS[theme];
  return (
    <div style={{ display: 'flex', flexDirection: 'column', alignItems: 'flex-start', gap: 14 }}>
      {label && (
        <div style={{
          fontFamily: MN_FONTS.body, fontSize: 12, fontWeight: 500,
          color: 'rgba(40,30,40,0.65)', letterSpacing: 0.2,
          paddingLeft: 4,
        }}>{label}</div>
      )}
      <div style={{
        width: 412, height: 892,
        background: t.bg,
        borderRadius: 44,
        padding: 8,
        boxShadow: `0 0 0 1.5px ${t.frameBorder}, 0 40px 80px -30px rgba(28,27,46,0.35), 0 10px 30px -10px rgba(28,27,46,0.2)`,
        boxSizing: 'border-box',
        position: 'relative',
      }}>
        <div style={{
          width: '100%', height: '100%',
          background: t.bg,
          borderRadius: 36,
          overflow: 'hidden',
          display: 'flex', flexDirection: 'column',
          position: 'relative',
          fontFamily: MN_FONTS.body,
          color: t.onSurface,
        }}>
          <MNStatusBar theme={theme} />
          <div style={{ flex: 1, minHeight: 0, display: 'flex', flexDirection: 'column', position: 'relative' }}>
            {children}
          </div>
          <MNGestureBar theme={theme} />
        </div>
      </div>
    </div>
  );
}

function MNStatusBar({ theme, time = '9:41' }) {
  const t = MN_TOKENS[theme];
  const c = t.onSurface;
  return (
    <div style={{
      height: 40, flexShrink: 0,
      display: 'flex', alignItems: 'center', justifyContent: 'space-between',
      padding: '0 24px',
      position: 'relative',
      fontFamily: MN_FONTS.body,
    }}>
      <div style={{ fontSize: 14, fontWeight: 600, color: c, letterSpacing: 0.2 }}>{time}</div>
      {/* camera punch-hole */}
      <div style={{
        position: 'absolute', left: '50%', top: 10, transform: 'translateX(-50%)',
        width: 12, height: 12, borderRadius: '50%',
        background: '#0B0A15',
      }} />
      <div style={{ display: 'flex', alignItems: 'center', gap: 6, color: c }}>
        {/* signal */}
        <svg width="16" height="11" viewBox="0 0 16 11"><path d="M1 9h2v2H1zM5 7h2v4H5zM9 5h2v6H9zM13 2h2v9h-2z" fill={c} /></svg>
        {/* wifi */}
        <svg width="15" height="11" viewBox="0 0 15 11"><path d="M7.5 2a10 10 0 0 1 7 3l-1.4 1.4A8 8 0 0 0 7.5 4 8 8 0 0 0 1.9 6.4L.5 5a10 10 0 0 1 7-3Zm0 3a7 7 0 0 1 4.9 2l-1.4 1.4a5 5 0 0 0-7 0L2.6 7A7 7 0 0 1 7.5 5Zm0 3a4 4 0 0 1 2.8 1.2L7.5 11 4.7 9.2A4 4 0 0 1 7.5 8Z" fill={c} /></svg>
        {/* battery */}
        <svg width="24" height="11" viewBox="0 0 24 11">
          <rect x="0.5" y="0.5" width="21" height="10" rx="2.5" fill="none" stroke={c} strokeOpacity="0.5" />
          <rect x="22.5" y="3.5" width="1.5" height="4" rx="0.5" fill={c} fillOpacity="0.5" />
          <rect x="2" y="2" width="16" height="7" rx="1.5" fill={c} />
        </svg>
      </div>
    </div>
  );
}

function MNGestureBar({ theme }) {
  const t = MN_TOKENS[theme];
  return (
    <div style={{
      height: 24, flexShrink: 0,
      display: 'flex', alignItems: 'flex-end', justifyContent: 'center',
      paddingBottom: 8,
    }}>
      <div style={{
        width: 128, height: 4, borderRadius: 2,
        background: t.onSurface, opacity: 0.5,
      }} />
    </div>
  );
}

// Pill bottom nav with floating indicator on active tab.
function MNBottomNav({ theme, active = 0 }) {
  const t = MN_TOKENS[theme];
  const tabs = [
    { id: 'home', icon: 'notes', label: 'Home' },
    { id: 'explore', icon: 'explore', label: 'Explore' },
    { id: 'tags', icon: 'tag', label: 'Tags' },
    { id: 'settings', icon: 'settings', label: 'Settings' },
  ];
  return (
    <div style={{
      position: 'absolute', left: 16, right: 16, bottom: 14,
      height: 64,
      background: t.card,
      border: `0.5px solid ${t.outlineStrong}`,
      borderRadius: 32,
      display: 'flex',
      alignItems: 'center',
      padding: 6,
      boxShadow: theme === 'light'
        ? '0 2px 8px rgba(28,27,46,0.04)'
        : '0 2px 8px rgba(0,0,0,0.35)',
    }}>
      {tabs.map((tab, i) => {
        const isActive = i === active;
        return (
          <div key={tab.id} style={{
            flex: 1, height: '100%',
            borderRadius: 26,
            background: isActive ? t.primaryContainer : 'transparent',
            display: 'flex', alignItems: 'center', justifyContent: 'center',
            gap: 6,
            transition: 'background 0.25s',
          }}>
            <MNIcon name={tab.icon} size={20} color={isActive ? t.onPrimaryContainer : t.onSurfaceVariant} strokeWidth={isActive ? 2 : 1.75} />
            {isActive && (
              <div style={{
                fontFamily: MN_FONTS.body, fontSize: 13, fontWeight: 600,
                color: t.onPrimaryContainer, letterSpacing: 0.1,
              }}>{tab.label}</div>
            )}
          </div>
        );
      })}
    </div>
  );
}

// Amber FAB
function MNFab({ theme, icon = 'plus', label, bottom = 96, right = 20, onClick }) {
  const t = MN_TOKENS[theme];
  return (
    <div style={{
      position: 'absolute', bottom, right,
      height: 56,
      padding: label ? '0 22px 0 20px' : 0,
      width: label ? 'auto' : 56,
      minWidth: 56,
      background: t.accent,
      borderRadius: 18,
      display: 'flex', alignItems: 'center', justifyContent: 'center', gap: 10,
      boxShadow: '0 6px 16px -4px rgba(245,158,11,0.55), 0 2px 4px rgba(28,27,46,0.12)',
      cursor: 'pointer',
    }} onClick={onClick}>
      <MNIcon name={icon} size={26} color={t.accentOn} strokeWidth={2.25} />
      {label && (
        <div style={{
          fontFamily: MN_FONTS.head, fontSize: 15, fontWeight: 700, color: t.accentOn,
        }}>{label}</div>
      )}
    </div>
  );
}

// Chip — filled/outlined variants
function MNChip({ theme, label, variant = 'filled', onDismiss, icon, leading, size = 'md' }) {
  const t = MN_TOKENS[theme];
  const isFilled = variant === 'filled';
  const isGhost = variant === 'ghost';
  const h = size === 'sm' ? 24 : 30;
  const fs = size === 'sm' ? 11 : 12.5;
  return (
    <div style={{
      display: 'inline-flex', alignItems: 'center', gap: 6,
      height: h,
      padding: `0 ${onDismiss ? 6 : 12}px 0 ${leading || icon ? 8 : 12}px`,
      borderRadius: 999,
      background: isFilled ? t.chipBg : isGhost ? 'transparent' : t.card,
      border: isFilled ? 'none' : `1px dashed ${t.outlineStrong}`,
      color: isFilled ? t.chipText : t.onSurfaceVariant,
      fontFamily: MN_FONTS.body, fontSize: fs, fontWeight: 600,
      letterSpacing: 0.1,
      whiteSpace: 'nowrap',
    }}>
      {leading}
      {icon && <MNIcon name={icon} size={13} color={isFilled ? t.chipText : t.onSurfaceVariant} strokeWidth={2} />}
      <span>{label}</span>
      {onDismiss && (
        <div style={{ width: 16, height: 16, borderRadius: '50%', background: 'rgba(0,0,0,0.08)',
          display: 'flex', alignItems: 'center', justifyContent: 'center', marginLeft: 2, marginRight: -2 }}>
          <MNIcon name="close" size={10} color={isFilled ? t.chipText : t.onSurfaceVariant} strokeWidth={2.5} />
        </div>
      )}
    </div>
  );
}

// Note card — used on Home + Explore
function MNNoteCard({ theme, note }) {
  const t = MN_TOKENS[theme];
  const pinned = note.pinned;
  return (
    <div style={{
      background: pinned ? (theme === 'light' ? t.pinTint : t.card) : t.card,
      border: `0.5px solid ${pinned ? 'rgba(245,158,11,0.35)' : t.outline}`,
      borderRadius: 20,
      padding: '16px 18px',
      display: 'flex', flexDirection: 'column', gap: 10,
    }}>
      <div style={{ display: 'flex', alignItems: 'flex-start', gap: 8 }}>
        {pinned && (
          <div style={{ marginTop: 3, flexShrink: 0 }}>
            <MNIcon name="pinSolid" size={14} color={t.accent} />
          </div>
        )}
        <div style={{
          flex: 1, minWidth: 0,
          fontFamily: MN_FONTS.head, fontSize: 16.5, fontWeight: 700,
          color: t.onSurface, lineHeight: 1.25, letterSpacing: -0.2,
        }}>{note.title}</div>
        <div style={{
          fontFamily: MN_FONTS.body, fontSize: 11.5, fontWeight: 500,
          color: t.onSurfaceMuted, marginTop: 2, flexShrink: 0,
        }}>{note.time}</div>
      </div>
      <div style={{
        fontFamily: MN_FONTS.body, fontSize: 13.5, fontWeight: 400,
        color: t.onSurfaceVariant, lineHeight: 1.4,
        overflow: 'hidden', textOverflow: 'ellipsis', whiteSpace: 'nowrap',
      }}>{note.preview}</div>
      {note.tags && note.tags.length > 0 && (
        <div style={{ display: 'flex', gap: 6, marginTop: 2, flexWrap: 'wrap' }}>
          {note.tags.slice(0, 3).map(tag => (
            <MNChip key={tag} theme={theme} label={`#${tag}`} size="sm" />
          ))}
        </div>
      )}
    </div>
  );
}

// Search input (flat, filled pill)
function MNSearchField({ theme, placeholder = 'Search notes, tags…', value }) {
  const t = MN_TOKENS[theme];
  return (
    <div style={{
      height: 48,
      background: t.surfaceContainer,
      borderRadius: 16,
      border: `0.5px solid ${t.outline}`,
      display: 'flex', alignItems: 'center', gap: 10,
      padding: '0 16px',
    }}>
      <MNIcon name="search" size={20} color={t.onSurfaceMuted} />
      <div style={{
        flex: 1, fontFamily: MN_FONTS.body, fontSize: 14.5,
        color: value ? t.onSurface : t.onSurfaceMuted, fontWeight: value ? 500 : 400,
      }}>{value || placeholder}</div>
    </div>
  );
}

Object.assign(window, { MNPhone, MNStatusBar, MNGestureBar, MNBottomNav, MNFab, MNChip, MNNoteCard, MNSearchField });
