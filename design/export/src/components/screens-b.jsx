// Screens 4-6: Editor (idle + recording), Category Picker, Settings

function MNEditorToolbar({ theme }) {
  const t = MN_TOKENS[theme];
  const tools = ['bold', 'italic', 'underline', 'h1', 'h2', 'bullet', 'numList', 'checklist', 'quote'];
  return (
    <div style={{
      background: t.card,
      borderTop: `0.5px solid ${t.outline}`,
      padding: '10px 12px',
      display: 'flex', alignItems: 'center', justifyContent: 'space-between',
      overflow: 'hidden',
    }}>
      {tools.map((tool, i) => (
        <div key={tool} style={{
          width: 34, height: 34, borderRadius: 10,
          background: i === 0 ? t.primaryContainer : 'transparent',
          display: 'flex', alignItems: 'center', justifyContent: 'center',
          flexShrink: 0,
        }}>
          <MNIcon name={tool} size={18} color={i === 0 ? t.onPrimaryContainer : t.onSurfaceVariant} strokeWidth={1.75} />
        </div>
      ))}
    </div>
  );
}

function MNTagRow({ theme, recording = false }) {
  const t = MN_TOKENS[theme];
  return (
    <div style={{
      padding: '12px 16px',
      borderTop: `0.5px solid ${t.outline}`,
      display: 'flex', alignItems: 'center', gap: 8,
      background: t.bg,
    }}>
      {/* category chip */}
      <div style={{
        display: 'inline-flex', alignItems: 'center', gap: 6,
        height: 30, padding: '0 12px',
        borderRadius: 10,
        background: t.surfaceContainer,
        border: `0.5px solid ${t.outline}`,
        flexShrink: 0,
      }}>
        <MNIcon name="folder" size={14} color={t.onSurfaceVariant} strokeWidth={1.75} />
        <div style={{
          fontFamily: MN_FONTS.body, fontSize: 12, fontWeight: 600,
          color: t.onSurfaceVariant,
        }}>YouTube</div>
        <MNIcon name="chevronDown" size={12} color={t.onSurfaceMuted} strokeWidth={2} />
      </div>
      {/* tag chips scrollable */}
      <div style={{ flex: 1, display: 'flex', gap: 6, overflow: 'hidden' }}>
        <MNChip theme={theme} label="#youtube" size="sm" onDismiss />
        <MNChip theme={theme} label="#tokyo" size="sm" onDismiss />
        <MNChip theme={theme} label="+ tag" size="sm" variant="outlined" />
      </div>
      {/* mic */}
      <div style={{
        width: 40, height: 40, borderRadius: 14,
        background: recording ? t.recordRed : t.primaryContainer,
        display: 'flex', alignItems: 'center', justifyContent: 'center',
        flexShrink: 0,
        boxShadow: recording ? `0 0 0 6px ${t.recordRed}26` : 'none',
        position: 'relative',
      }}>
        <MNIcon name={recording ? 'stop' : 'mic'} size={recording ? 14 : 20} color={recording ? '#fff' : t.onPrimaryContainer} strokeWidth={2} />
        {recording && (
          <div style={{
            position: 'absolute', top: -4, right: -4,
            width: 10, height: 10, borderRadius: '50%',
            background: t.recordRed,
            border: `2px solid ${t.bg}`,
            animation: 'mn-pulse 1.2s ease-in-out infinite',
          }} />
        )}
      </div>
    </div>
  );
}

function ScreenEditor({ theme, recording = false }) {
  const t = MN_TOKENS[theme];
  return (
    <>
      {/* app bar */}
      <div style={{
        padding: '4px 12px 8px',
        display: 'flex', alignItems: 'center', gap: 6,
      }}>
        <div style={{
          width: 40, height: 40, borderRadius: '50%',
          display: 'flex', alignItems: 'center', justifyContent: 'center',
        }}>
          <MNIcon name="back" size={22} color={t.onSurface} />
        </div>
        <div style={{
          flex: 1,
          fontFamily: MN_FONTS.head, fontSize: 17, fontWeight: 700,
          color: t.onSurface, letterSpacing: -0.2,
        }}>Hook ideas for the Tokyo vlog</div>
        <div style={{
          fontFamily: MN_FONTS.body, fontSize: 11.5, fontWeight: 500,
          color: t.onSurfaceMuted,
          padding: '4px 10px', borderRadius: 100,
          background: t.surfaceContainer,
          display: 'flex', alignItems: 'center', gap: 5,
        }}>
          <div style={{ width: 6, height: 6, borderRadius: '50%', background: '#22c55e' }} />
          Saved
        </div>
        <div style={{
          width: 40, height: 40, borderRadius: '50%',
          display: 'flex', alignItems: 'center', justifyContent: 'center',
        }}>
          <MNIcon name="more" size={22} color={t.onSurface} />
        </div>
      </div>

      {/* editor body */}
      <div style={{
        flex: 1, overflow: 'hidden',
        padding: '8px 20px 4px',
        fontFamily: MN_FONTS.body,
        color: t.onSurface,
        display: 'flex', flexDirection: 'column', gap: 10,
        position: 'relative',
      }}>
        <div style={{
          fontFamily: MN_FONTS.head, fontSize: 13, fontWeight: 700,
          color: t.primary, letterSpacing: 0.4, textTransform: 'uppercase',
        }}>Opening sequence</div>

        <div style={{ fontSize: 15.5, lineHeight: 1.55, color: t.onSurface }}>
          Open on <span style={{ fontWeight: 700 }}>Shinjuku crossing</span> at night, slowed-down crowd, neon reflecting in puddles. Cut hard to a quiet hotel window — same rain, different energy.
        </div>

        <div style={{ fontSize: 15.5, lineHeight: 1.55, color: t.onSurface }}>
          Voiceover starts <span style={{ fontStyle: 'italic' }}>mid-thought</span>, no intro. Viewer should feel like they're walking in halfway through a conversation.
        </div>

        <div style={{
          fontFamily: MN_FONTS.head, fontSize: 13, fontWeight: 700,
          color: t.primary, letterSpacing: 0.4, textTransform: 'uppercase', marginTop: 8,
        }}>Three candidate hooks</div>

        {/* checklist */}
        {[
          { c: true,  t: '"I gave myself 48 hours, one camera, and no map."' },
          { c: true,  t: '"The worst jetlag of my life turned into the best shot."' },
          { c: false, t: '"Tokyo in the rain is louder than Tokyo in the sun."' },
        ].map((item, i) => (
          <div key={i} style={{ display: 'flex', gap: 12, alignItems: 'flex-start' }}>
            <div style={{
              width: 20, height: 20, borderRadius: 6, marginTop: 2,
              background: item.c ? t.primary : 'transparent',
              border: item.c ? 'none' : `1.5px solid ${t.outlineStrong}`,
              display: 'flex', alignItems: 'center', justifyContent: 'center',
              flexShrink: 0,
            }}>
              {item.c && <MNIcon name="check" size={14} color="#fff" strokeWidth={3} />}
            </div>
            <div style={{
              flex: 1, fontSize: 14.5, lineHeight: 1.45,
              color: item.c ? t.onSurfaceMuted : t.onSurface,
              textDecoration: item.c ? 'line-through' : 'none',
            }}>{item.t}</div>
          </div>
        ))}

        {/* blockquote */}
        <div style={{
          marginTop: 6, padding: '10px 14px',
          borderLeft: `3px solid ${t.accent}`,
          background: t.surfaceContainer,
          borderRadius: '0 12px 12px 0',
          fontSize: 13.5, lineHeight: 1.5, fontStyle: 'italic',
          color: t.onSurfaceVariant,
        }}>
          "If the first 3 seconds don't earn the next 30, I cut them."
        </div>

        {/* recording waveform overlay */}
        {recording && (
          <div style={{
            position: 'absolute', left: 16, right: 16, bottom: 8,
            background: t.card,
            border: `1px solid ${t.recordRed}`,
            borderRadius: 20,
            padding: '14px 16px',
            display: 'flex', alignItems: 'center', gap: 12,
            boxShadow: '0 10px 30px -8px rgba(229,72,77,0.35)',
          }}>
            <div style={{
              width: 36, height: 36, borderRadius: '50%',
              background: t.recordRed,
              display: 'flex', alignItems: 'center', justifyContent: 'center',
              boxShadow: `0 0 0 4px ${t.recordRed}33`,
              animation: 'mn-pulse 1.2s ease-in-out infinite',
              flexShrink: 0,
            }}>
              <div style={{ width: 10, height: 10, borderRadius: 2, background: '#fff' }} />
            </div>
            <div style={{ flex: 1, minWidth: 0 }}>
              <div style={{
                display: 'flex', alignItems: 'center', gap: 8, marginBottom: 4,
              }}>
                <div style={{
                  fontFamily: MN_FONTS.head, fontSize: 13, fontWeight: 700,
                  color: t.recordRed, letterSpacing: 0.2,
                }}>Recording</div>
                <div style={{
                  fontFamily: MN_FONTS.body, fontSize: 12, fontWeight: 500,
                  color: t.onSurfaceMuted,
                }}>0:12</div>
              </div>
              {/* waveform */}
              <div style={{ display: 'flex', alignItems: 'center', gap: 2, height: 22 }}>
                {[4,8,14,20,12,6,10,18,22,16,8,4,10,18,14,6,12,20,14,8,4,10,14,20,12,6,8,14].map((h, i) => (
                  <div key={i} style={{
                    flex: 1, height: `${h * 0.9}px`,
                    background: i < 18 ? t.recordRed : t.outlineStrong,
                    borderRadius: 1,
                  }} />
                ))}
              </div>
            </div>
          </div>
        )}
      </div>

      <MNTagRow theme={theme} recording={recording} />
      <MNEditorToolbar theme={theme} />
    </>
  );
}

function ScreenCategoryPicker({ theme }) {
  const t = MN_TOKENS[theme];
  // Blurred editor behind
  return (
    <div style={{ position: 'relative', height: '100%' }}>
      {/* dim backdrop */}
      <div style={{ position: 'absolute', inset: 0, background: t.bg, overflow: 'hidden' }}>
        <div style={{ opacity: 0.35, filter: 'blur(1px)' }}>
          <div style={{ padding: '16px 20px', fontFamily: MN_FONTS.head, fontSize: 17, fontWeight: 700, color: t.onSurface }}>
            Hook ideas for the Tokyo vlog
          </div>
          <div style={{ padding: '0 20px', fontSize: 14, color: t.onSurfaceVariant, lineHeight: 1.5 }}>
            Open on Shinjuku crossing at night, slowed-down crowd, neon reflecting in puddles.
          </div>
        </div>
        <div style={{ position: 'absolute', inset: 0, background: theme === 'light' ? 'rgba(28,27,46,0.35)' : 'rgba(0,0,0,0.55)' }} />
      </div>

      {/* sheet */}
      <div style={{
        position: 'absolute', left: 0, right: 0, bottom: 0,
        background: t.card,
        borderTopLeftRadius: 28, borderTopRightRadius: 28,
        padding: '12px 0 24px',
        boxShadow: '0 -20px 40px -10px rgba(0,0,0,0.25)',
      }}>
        {/* grabber */}
        <div style={{ display: 'flex', justifyContent: 'center', paddingBottom: 12 }}>
          <div style={{ width: 36, height: 4, borderRadius: 2, background: t.outlineStrong }} />
        </div>
        {/* header */}
        <div style={{ padding: '0 20px 12px', display: 'flex', alignItems: 'center', justifyContent: 'space-between' }}>
          <div>
            <div style={{ fontFamily: MN_FONTS.head, fontSize: 19, fontWeight: 800, color: t.onSurface, letterSpacing: -0.3 }}>
              Move to category
            </div>
            <div style={{ fontFamily: MN_FONTS.body, fontSize: 12.5, color: t.onSurfaceMuted, marginTop: 2 }}>
              Organize this note in your folder tree
            </div>
          </div>
          <div style={{ width: 34, height: 34, borderRadius: '50%', background: t.surfaceContainer, display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
            <MNIcon name="close" size={18} color={t.onSurfaceVariant} strokeWidth={2} />
          </div>
        </div>

        {/* tree */}
        <div style={{ padding: '0 12px' }}>
          {[
            { id: 'inbox', name: 'Inbox', icon: 'folder', depth: 0, expanded: false },
            { id: 'video', name: 'Video Ideas', icon: 'folderOpen', depth: 0, expanded: true },
            { id: 'yt',    name: 'YouTube', icon: 'folderOpen', depth: 1, expanded: true, selected: true },
            { id: 'vlogs', name: 'Travel vlogs', icon: 'folder', depth: 2 },
            { id: 'gear',  name: 'Gear reviews', icon: 'folder', depth: 2 },
            { id: 'ig',    name: 'Instagram Reels', icon: 'folder', depth: 1 },
            { id: 'shorts',name: 'YouTube Shorts', icon: 'folder', depth: 1 },
            { id: 'writing', name: 'Writing', icon: 'folder', depth: 0 },
            { id: 'biz',   name: 'Business', icon: 'folder', depth: 0 },
          ].map((row) => (
            <div key={row.id} style={{
              display: 'flex', alignItems: 'center', gap: 10,
              padding: '10px 10px',
              paddingLeft: 10 + row.depth * 20,
              borderRadius: 14,
              background: row.selected ? t.primaryContainer : 'transparent',
            }}>
              {row.icon.startsWith('folderOpen') ? (
                <MNIcon name="chevronDown" size={14} color={t.onSurfaceVariant} strokeWidth={2} />
              ) : row.depth === 0 || row.depth === 1 ? (
                <MNIcon name="chevron" size={14} color={t.onSurfaceMuted} strokeWidth={2} />
              ) : (
                <div style={{ width: 14 }} />
              )}
              <MNIcon name={row.icon} size={18} color={row.selected ? t.onPrimaryContainer : t.primary} strokeWidth={1.75} />
              <div style={{
                flex: 1, fontFamily: MN_FONTS.head, fontSize: 14.5,
                fontWeight: row.selected ? 700 : 600,
                color: row.selected ? t.onPrimaryContainer : t.onSurface,
                letterSpacing: -0.1,
              }}>{row.name}</div>
              {row.selected && <MNIcon name="check" size={18} color={t.onPrimaryContainer} strokeWidth={2.5} />}
            </div>
          ))}

          {/* new category */}
          <div style={{
            marginTop: 8,
            padding: '12px 14px',
            borderRadius: 14,
            border: `1px dashed ${t.outlineStrong}`,
            display: 'flex', alignItems: 'center', gap: 10,
          }}>
            <div style={{
              width: 26, height: 26, borderRadius: 8,
              background: t.accent,
              display: 'flex', alignItems: 'center', justifyContent: 'center',
            }}>
              <MNIcon name="plus" size={16} color={t.accentOn} strokeWidth={2.5} />
            </div>
            <div style={{ fontFamily: MN_FONTS.head, fontSize: 14, fontWeight: 700, color: t.onSurface }}>
              New category
            </div>
            <div style={{ flex: 1 }} />
            <div style={{ fontFamily: MN_FONTS.body, fontSize: 12, color: t.onSurfaceMuted }}>
              Under · YouTube
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}

function ScreenSettings({ theme }) {
  const t = MN_TOKENS[theme];
  const dark = theme === 'dark';
  return (
    <>
      {/* app bar */}
      <div style={{ padding: '4px 20px 8px' }}>
        <div style={{ fontFamily: MN_FONTS.head, fontSize: 24, fontWeight: 800, color: t.onSurface, letterSpacing: -0.5 }}>
          Settings
        </div>
      </div>

      <div style={{ flex: 1, overflow: 'hidden', padding: '8px 20px 150px', display: 'flex', flexDirection: 'column', gap: 16 }}>
        {/* Theme card — two options, selected state */}
        <div style={{
          background: t.card,
          border: `0.5px solid ${t.outline}`,
          borderRadius: 22,
          padding: 16,
        }}>
          <div style={{ fontFamily: MN_FONTS.head, fontSize: 15, fontWeight: 700, color: t.onSurface, marginBottom: 4 }}>
            Appearance
          </div>
          <div style={{ fontFamily: MN_FONTS.body, fontSize: 12.5, color: t.onSurfaceMuted, marginBottom: 14 }}>
            Matches system by default.
          </div>
          <div style={{ display: 'flex', gap: 10 }}>
            {[
              { id: 'light', label: 'Light', icon: 'sun', selected: !dark },
              { id: 'dark',  label: 'Dark',  icon: 'moon', selected: dark },
            ].map(opt => (
              <div key={opt.id} style={{
                flex: 1,
                border: opt.selected ? `2px solid ${t.primary}` : `0.5px solid ${t.outlineStrong}`,
                background: opt.selected ? t.primaryContainer : t.surfaceContainer,
                borderRadius: 16,
                padding: '14px 14px 12px',
                display: 'flex', flexDirection: 'column', gap: 10,
              }}>
                {/* mini preview */}
                <div style={{
                  height: 56, borderRadius: 10,
                  background: opt.id === 'light' ? '#FEFBFF' : '#1C1B2E',
                  border: `0.5px solid ${opt.id === 'light' ? 'rgba(0,0,0,0.1)' : 'rgba(255,255,255,0.1)'}`,
                  padding: 8,
                  display: 'flex', flexDirection: 'column', gap: 5,
                }}>
                  <div style={{ height: 6, width: '50%', borderRadius: 3, background: opt.id === 'light' ? '#1C1B2E' : '#FEFBFF', opacity: 0.85 }} />
                  <div style={{ height: 4, width: '80%', borderRadius: 2, background: opt.id === 'light' ? '#4A4858' : '#BDBAD0', opacity: 0.6 }} />
                  <div style={{ height: 4, width: '65%', borderRadius: 2, background: opt.id === 'light' ? '#4A4858' : '#BDBAD0', opacity: 0.4 }} />
                  <div style={{ display: 'flex', gap: 4, marginTop: 'auto' }}>
                    <div style={{ width: 14, height: 5, borderRadius: 2, background: '#5B4EFF', opacity: 0.7 }} />
                    <div style={{ width: 10, height: 5, borderRadius: 2, background: '#F59E0B', opacity: 0.9 }} />
                  </div>
                </div>
                <div style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
                  <MNIcon name={opt.icon} size={16} color={opt.selected ? t.onPrimaryContainer : t.onSurfaceVariant} strokeWidth={2} />
                  <div style={{ fontFamily: MN_FONTS.head, fontSize: 14, fontWeight: 700, color: opt.selected ? t.onPrimaryContainer : t.onSurface }}>
                    {opt.label}
                  </div>
                  <div style={{ flex: 1 }} />
                  <div style={{
                    width: 18, height: 18, borderRadius: '50%',
                    background: opt.selected ? t.primary : 'transparent',
                    border: opt.selected ? 'none' : `1.5px solid ${t.outlineStrong}`,
                    display: 'flex', alignItems: 'center', justifyContent: 'center',
                  }}>
                    {opt.selected && <MNIcon name="check" size={11} color="#fff" strokeWidth={3} />}
                  </div>
                </div>
              </div>
            ))}
          </div>
        </div>

        {/* Storage */}
        <div style={{
          background: t.card,
          border: `0.5px solid ${t.outline}`,
          borderRadius: 22,
          overflow: 'hidden',
        }}>
          <div style={{ padding: '16px 18px 8px' }}>
            <div style={{ fontFamily: MN_FONTS.head, fontSize: 15, fontWeight: 700, color: t.onSurface }}>Storage</div>
          </div>
          <SettingsRow theme={theme} icon="mic" label="Audio storage" meta="14.2 MB" subtitle="28 voice notes" />
          <SettingsRow theme={theme} icon="trash" label="Clear audio cache" meta={null} action="Clear" danger />
          <SettingsRow theme={theme} icon="download" label="Export all notes" meta="JSON · Markdown" last />
        </div>

        {/* About */}
        <div style={{
          background: t.card,
          border: `0.5px solid ${t.outline}`,
          borderRadius: 22,
          overflow: 'hidden',
        }}>
          <div style={{ padding: '16px 18px 8px' }}>
            <div style={{ fontFamily: MN_FONTS.head, fontSize: 15, fontWeight: 700, color: t.onSurface }}>About</div>
          </div>
          <SettingsRow theme={theme} icon="info" label="Version" meta="1.4.2 (build 412)" />
          <SettingsRow theme={theme} icon="shield" label="Privacy" meta={null} chevron />
          <SettingsRow theme={theme} icon="globe" label="Website" meta="modunote.app" last chevron />
        </div>
      </div>

      <MNBottomNav theme={theme} active={3} />
    </>
  );
}

function SettingsRow({ theme, icon, label, meta, subtitle, action, danger, chevron, last }) {
  const t = MN_TOKENS[theme];
  return (
    <div style={{
      display: 'flex', alignItems: 'center', gap: 14,
      padding: '12px 18px',
      borderTop: `0.5px solid ${t.outline}`,
    }}>
      <div style={{
        width: 34, height: 34, borderRadius: 10,
        background: danger ? 'rgba(229,72,77,0.12)' : t.surfaceContainer,
        display: 'flex', alignItems: 'center', justifyContent: 'center',
        flexShrink: 0,
      }}>
        <MNIcon name={icon} size={17} color={danger ? t.recordRed : t.onSurfaceVariant} strokeWidth={1.75} />
      </div>
      <div style={{ flex: 1, minWidth: 0 }}>
        <div style={{
          fontFamily: MN_FONTS.body, fontSize: 14, fontWeight: 600,
          color: danger ? t.recordRed : t.onSurface,
        }}>{label}</div>
        {subtitle && (
          <div style={{ fontFamily: MN_FONTS.body, fontSize: 12, color: t.onSurfaceMuted, marginTop: 1 }}>
            {subtitle}
          </div>
        )}
      </div>
      {meta && (
        <div style={{ fontFamily: MN_FONTS.body, fontSize: 12.5, fontWeight: 500, color: t.onSurfaceMuted }}>
          {meta}
        </div>
      )}
      {action && (
        <div style={{
          padding: '6px 12px', borderRadius: 100,
          background: 'rgba(229,72,77,0.1)',
          fontFamily: MN_FONTS.body, fontSize: 12, fontWeight: 700,
          color: t.recordRed,
        }}>{action}</div>
      )}
      {chevron && <MNIcon name="chevron" size={16} color={t.onSurfaceMuted} />}
    </div>
  );
}

Object.assign(window, { ScreenEditor, ScreenCategoryPicker, ScreenSettings });
