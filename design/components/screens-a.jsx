// Screens 1-3: Home, Explore, Tags

function ScreenHome({ theme }) {
  const t = MN_TOKENS[theme];
  return (
    <>
      {/* app bar */}
      <div style={{ padding: '4px 20px 0', display: 'flex', alignItems: 'center', justifyContent: 'space-between' }}>
        <div>
          <div style={{
            fontFamily: MN_FONTS.body, fontSize: 12, fontWeight: 500,
            color: t.onSurfaceMuted, letterSpacing: 0.4, textTransform: 'uppercase',
          }}>Sunday</div>
          <div style={{
            fontFamily: MN_FONTS.head, fontSize: 26, fontWeight: 800,
            color: t.onSurface, letterSpacing: -0.6, marginTop: 2,
          }}>Your notes</div>
        </div>
        <div style={{
          width: 42, height: 42, borderRadius: '50%',
          background: `linear-gradient(135deg, ${t.primary} 0%, ${t.accent} 100%)`,
          display: 'flex', alignItems: 'center', justifyContent: 'center',
          fontFamily: MN_FONTS.head, fontSize: 14, fontWeight: 800, color: '#fff',
        }}>MA</div>
      </div>

      {/* search */}
      <div style={{ padding: '16px 20px 0' }}>
        <MNSearchField theme={theme} />
      </div>

      {/* filter row */}
      <div style={{ padding: '14px 20px 4px', display: 'flex', gap: 6, alignItems: 'center' }}>
        <div style={{
          fontFamily: MN_FONTS.body, fontSize: 12, fontWeight: 600,
          color: t.onSurfaceMuted, letterSpacing: 0.6, textTransform: 'uppercase',
          marginRight: 6,
        }}>Pinned</div>
        <div style={{ flex: 1, height: 0.5, background: t.outline }} />
        <div style={{
          fontFamily: MN_FONTS.body, fontSize: 11, fontWeight: 500,
          color: t.onSurfaceMuted,
        }}>2</div>
      </div>

      {/* note list */}
      <div style={{
        flex: 1, overflow: 'hidden',
        padding: '10px 20px 150px',
        display: 'flex', flexDirection: 'column', gap: 10,
      }}>
        {MN_NOTES.filter(n => n.pinned).map(n => <MNNoteCard key={n.id} theme={theme} note={n} />)}
        <div style={{ display: 'flex', gap: 6, alignItems: 'center', margin: '10px 0 -2px' }}>
          <div style={{
            fontFamily: MN_FONTS.body, fontSize: 12, fontWeight: 600,
            color: t.onSurfaceMuted, letterSpacing: 0.6, textTransform: 'uppercase',
          }}>Recent</div>
          <div style={{ flex: 1, height: 0.5, background: t.outline }} />
        </div>
        {MN_NOTES.filter(n => !n.pinned).map(n => <MNNoteCard key={n.id} theme={theme} note={n} />)}
      </div>

      <MNFab theme={theme} />
      <MNBottomNav theme={theme} active={0} />
    </>
  );
}

function ScreenExplore({ theme, empty = false }) {
  const t = MN_TOKENS[theme];
  const filters = ['All', ...MN_TAGS.slice(0, 6).map(x => x.name)];
  const results = empty ? [] : MN_NOTES.filter(n => n.tags.includes('videography')).slice(0, 3);
  return (
    <>
      {/* app bar */}
      <div style={{ padding: '4px 20px 8px' }}>
        <div style={{
          fontFamily: MN_FONTS.head, fontSize: 24, fontWeight: 800,
          color: t.onSurface, letterSpacing: -0.5,
        }}>Explore</div>
      </div>

      {/* search */}
      <div style={{ padding: '8px 20px 0' }}>
        <MNSearchField theme={theme} value={empty ? 'kyoto' : 'videography'} />
      </div>

      {/* filter chips */}
      <div style={{ padding: '14px 0 6px' }}>
        <div style={{
          display: 'flex', gap: 8, padding: '0 20px',
          overflowX: 'auto',
        }}>
          {filters.map((f, i) => {
            const active = (empty && f === 'All') || (!empty && f === 'videography');
            return (
              <div key={f} style={{
                flexShrink: 0,
                height: 34, padding: '0 14px',
                borderRadius: 12,
                background: active ? t.primary : t.card,
                border: active ? 'none' : `0.5px solid ${t.outlineStrong}`,
                color: active ? '#fff' : t.onSurfaceVariant,
                fontFamily: MN_FONTS.body, fontSize: 13, fontWeight: 600,
                display: 'flex', alignItems: 'center', gap: 6,
              }}>
                {active && <MNIcon name="check" size={14} color="#fff" strokeWidth={2.5} />}
                {f === 'All' ? 'All' : `#${f}`}
              </div>
            );
          })}
        </div>
      </div>

      {/* results */}
      <div style={{ flex: 1, overflow: 'hidden', padding: '14px 20px 150px' }}>
        {empty ? (
          <div style={{
            display: 'flex', flexDirection: 'column', alignItems: 'center',
            justifyContent: 'center', padding: '60px 20px', gap: 20,
            height: '100%',
          }}>
            <div style={{
              width: 140, height: 140, borderRadius: 28,
              background: t.surfaceContainer,
              display: 'flex', alignItems: 'center', justifyContent: 'center',
              border: `0.5px solid ${t.outline}`,
              position: 'relative',
              overflow: 'hidden',
            }}>
              {/* subtly striped placeholder */}
              <div style={{
                position: 'absolute', inset: 0,
                backgroundImage: `repeating-linear-gradient(135deg, transparent 0 10px, ${t.outline} 10px 11px)`,
                opacity: 0.6,
              }} />
              <MNIcon name="search" size={48} color={t.onSurfaceMuted} strokeWidth={1.5} />
            </div>
            <div style={{ textAlign: 'center' }}>
              <div style={{
                fontFamily: MN_FONTS.head, fontSize: 18, fontWeight: 700,
                color: t.onSurface, letterSpacing: -0.3,
              }}>No notes found</div>
              <div style={{
                fontFamily: MN_FONTS.body, fontSize: 13.5, fontWeight: 400,
                color: t.onSurfaceMuted, marginTop: 6, maxWidth: 240, lineHeight: 1.4,
              }}>Try a different tag, or broaden your search.</div>
            </div>
          </div>
        ) : (
          <>
            <div style={{
              fontFamily: MN_FONTS.body, fontSize: 12, fontWeight: 600,
              color: t.onSurfaceMuted, letterSpacing: 0.4, textTransform: 'uppercase',
              marginBottom: 10,
            }}>{results.length} results in #videography</div>
            <div style={{ display: 'flex', flexDirection: 'column', gap: 10 }}>
              {results.map(n => <MNNoteCard key={n.id} theme={theme} note={n} />)}
            </div>
          </>
        )}
      </div>

      <MNBottomNav theme={theme} active={1} />
    </>
  );
}

function ScreenTags({ theme }) {
  const t = MN_TOKENS[theme];
  const maxCount = Math.max(...MN_TAGS.map(x => x.count));
  return (
    <>
      {/* app bar */}
      <div style={{
        padding: '4px 16px 8px 20px',
        display: 'flex', alignItems: 'center', justifyContent: 'space-between',
      }}>
        <div>
          <div style={{
            fontFamily: MN_FONTS.head, fontSize: 24, fontWeight: 800,
            color: t.onSurface, letterSpacing: -0.5,
          }}>Tags</div>
          <div style={{
            fontFamily: MN_FONTS.body, fontSize: 12.5, fontWeight: 400,
            color: t.onSurfaceMuted, marginTop: 2,
          }}>{MN_TAGS.length} tags · {MN_TAGS.reduce((s, x) => s + x.count, 0)} tagged notes</div>
        </div>
        <div style={{
          width: 40, height: 40, borderRadius: 14,
          background: t.primaryContainer,
          display: 'flex', alignItems: 'center', justifyContent: 'center',
        }}>
          <MNIcon name="plus" size={20} color={t.onPrimaryContainer} strokeWidth={2.25} />
        </div>
      </div>

      {/* tags list */}
      <div style={{ flex: 1, overflow: 'hidden', padding: '14px 20px 150px' }}>
        <div style={{
          background: t.card,
          border: `0.5px solid ${t.outline}`,
          borderRadius: 20,
          padding: 6,
          display: 'flex', flexDirection: 'column',
        }}>
          {MN_TAGS.map((tag, i) => (
            <div key={tag.name} style={{
              display: 'flex', alignItems: 'center', gap: 14,
              padding: '12px 14px',
              borderBottom: i < MN_TAGS.length - 1 ? `0.5px solid ${t.outline}` : 'none',
            }}>
              <div style={{
                width: 36, height: 36, borderRadius: 12,
                background: t.chipBg,
                display: 'flex', alignItems: 'center', justifyContent: 'center',
              }}>
                <MNIcon name="hash" size={18} color={t.chipText} strokeWidth={2} />
              </div>
              <div style={{ flex: 1, minWidth: 0 }}>
                <div style={{
                  fontFamily: MN_FONTS.head, fontSize: 15, fontWeight: 700,
                  color: t.onSurface, letterSpacing: -0.1,
                }}>{tag.name}</div>
                {/* density bar */}
                <div style={{
                  height: 3, width: '100%', background: t.surfaceContainer,
                  borderRadius: 2, marginTop: 6, overflow: 'hidden',
                }}>
                  <div style={{
                    height: '100%', width: `${(tag.count / maxCount) * 100}%`,
                    background: t.primary, opacity: 0.55, borderRadius: 2,
                  }} />
                </div>
              </div>
              <div style={{
                fontFamily: MN_FONTS.body, fontSize: 12, fontWeight: 600,
                color: t.onSurfaceMuted,
                padding: '4px 10px', borderRadius: 100,
                background: t.surfaceContainer,
              }}>{tag.count} notes</div>
              <MNIcon name="chevron" size={16} color={t.onSurfaceMuted} />
            </div>
          ))}
        </div>
      </div>

      <MNBottomNav theme={theme} active={2} />
    </>
  );
}

Object.assign(window, { ScreenHome, ScreenExplore, ScreenTags });
