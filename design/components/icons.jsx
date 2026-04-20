// Material-style outlined icons at 24px. Stroke-based so they scale crisply.
const MNIcon = ({ name, size = 24, color = 'currentColor', strokeWidth = 1.75, fill = 'none' }) => {
  const p = { fill: fill === 'none' ? 'none' : color, stroke: color, strokeWidth, strokeLinecap: 'round', strokeLinejoin: 'round' };
  const paths = {
    search: <><circle cx="11" cy="11" r="7" {...p} /><path d="m20 20-3.5-3.5" {...p} /></>,
    home: <path d="M3 10.5 12 3l9 7.5V20a1 1 0 0 1-1 1h-5v-6h-6v6H4a1 1 0 0 1-1-1v-9.5Z" {...p} />,
    notes: <><rect x="4" y="3" width="16" height="18" rx="2" {...p} /><path d="M8 8h8M8 12h8M8 16h5" {...p} /></>,
    explore: <><circle cx="12" cy="12" r="9" {...p} /><path d="m15 9-4 2-2 4 4-2 2-4Z" {...p} fill={color} fillOpacity="0.15" /></>,
    tag: <><path d="M3 12V4a1 1 0 0 1 1-1h8l9 9-9 9-9-9Z" {...p} /><circle cx="8" cy="8" r="1.5" fill={color} /></>,
    settings: <><circle cx="12" cy="12" r="3" {...p} /><path d="M19.4 15a1.7 1.7 0 0 0 .3 1.8l.1.1a2 2 0 1 1-2.8 2.8l-.1-.1a1.7 1.7 0 0 0-1.8-.3 1.7 1.7 0 0 0-1 1.5V21a2 2 0 1 1-4 0v-.1a1.7 1.7 0 0 0-1.1-1.5 1.7 1.7 0 0 0-1.8.3l-.1.1a2 2 0 1 1-2.8-2.8l.1-.1a1.7 1.7 0 0 0 .3-1.8 1.7 1.7 0 0 0-1.5-1H3a2 2 0 1 1 0-4h.1a1.7 1.7 0 0 0 1.5-1.1 1.7 1.7 0 0 0-.3-1.8l-.1-.1a2 2 0 1 1 2.8-2.8l.1.1a1.7 1.7 0 0 0 1.8.3H9a1.7 1.7 0 0 0 1-1.5V3a2 2 0 1 1 4 0v.1a1.7 1.7 0 0 0 1 1.5 1.7 1.7 0 0 0 1.8-.3l.1-.1a2 2 0 1 1 2.8 2.8l-.1.1a1.7 1.7 0 0 0-.3 1.8V9a1.7 1.7 0 0 0 1.5 1H21a2 2 0 1 1 0 4h-.1a1.7 1.7 0 0 0-1.5 1Z" {...p} /></>,
    plus: <path d="M12 5v14M5 12h14" {...p} />,
    back: <path d="M15 6l-6 6 6 6" {...p} />,
    more: <><circle cx="12" cy="5" r="1.5" fill={color} /><circle cx="12" cy="12" r="1.5" fill={color} /><circle cx="12" cy="19" r="1.5" fill={color} /></>,
    close: <path d="M6 6l12 12M18 6 6 18" {...p} />,
    check: <path d="m5 12 4.5 4.5L19 7" {...p} />,
    mic: <><rect x="9" y="3" width="6" height="12" rx="3" {...p} /><path d="M5 11a7 7 0 0 0 14 0M12 18v3" {...p} /></>,
    stop: <rect x="6" y="6" width="12" height="12" rx="2" {...p} fill={color} />,
    pin: <path d="M12 2 9 7l-5 1 3.5 3.5L6 17l6-3 6 3-1.5-5.5L20 8l-5-1-3-5Z" {...p} fill={color} fillOpacity="0.15" />,
    pinSolid: <path d="M14 3h-4v6l-3 3v2h4v5l1 1 1-1v-5h4v-2l-3-3V3Z" fill={color} stroke={color} strokeWidth="1.25" strokeLinejoin="round" />,
    folder: <path d="M3 6a1 1 0 0 1 1-1h5l2 2h8a1 1 0 0 1 1 1v10a1 1 0 0 1-1 1H4a1 1 0 0 1-1-1V6Z" {...p} />,
    folderOpen: <path d="M3 7a1 1 0 0 1 1-1h5l2 2h8a1 1 0 0 1 1 1v1H3V7Zm0 3h18l-2 8a1 1 0 0 1-1 .8H5a1 1 0 0 1-1-.8L3 10Z" {...p} />,
    chevron: <path d="m9 6 6 6-6 6" {...p} />,
    chevronDown: <path d="m6 9 6 6 6-6" {...p} />,
    bold: <path d="M7 5h6a3.5 3.5 0 0 1 0 7H7V5Zm0 7h7a3.5 3.5 0 0 1 0 7H7v-7Z" {...p} strokeWidth="2" />,
    italic: <path d="M10 5h8M6 19h8M14 5l-4 14" {...p} strokeWidth="2" />,
    underline: <path d="M7 4v8a5 5 0 0 0 10 0V4M5 21h14" {...p} strokeWidth="2" />,
    h1: <><path d="M5 5v14M13 5v14M5 12h8" {...p} strokeWidth="2" /><path d="M17 8l3-1v12" {...p} strokeWidth="2" /></>,
    h2: <><path d="M5 5v14M13 5v14M5 12h8" {...p} strokeWidth="2" /><path d="M17 9a2 2 0 0 1 4 0c0 3-4 4-4 7h4" {...p} strokeWidth="2" /></>,
    bullet: <><circle cx="5" cy="7" r="1.3" fill={color} /><circle cx="5" cy="12" r="1.3" fill={color} /><circle cx="5" cy="17" r="1.3" fill={color} /><path d="M10 7h10M10 12h10M10 17h10" {...p} strokeWidth="2" /></>,
    numList: <><path d="M4 6h1v4H4M4 10h2M4 16l2-2h-2" {...p} /><path d="M10 7h10M10 12h10M10 17h10" {...p} strokeWidth="2" /></>,
    checklist: <><rect x="3" y="4" width="6" height="6" rx="1.5" {...p} /><rect x="3" y="14" width="6" height="6" rx="1.5" {...p} /><path d="m4.5 17 1.5 1.5L9 15" {...p} strokeWidth="1.5" /><path d="M12 7h10M12 17h10" {...p} strokeWidth="2" /></>,
    quote: <path d="M6 7c-1.5 1.5-2 3.5-2 6v4h5v-5H5c0-2 .5-3 1.5-4L6 7Zm9 0c-1.5 1.5-2 3.5-2 6v4h5v-5h-4c0-2 .5-3 1.5-4L15 7Z" {...p} fill={color} fillOpacity="0.15" />,
    hash: <path d="M6 3 4 21M18 3l-2 18M3 9h18M2 15h18" {...p} strokeWidth="1.6" />,
    sun: <><circle cx="12" cy="12" r="4" {...p} /><path d="M12 2v2M12 20v2M4.9 4.9l1.4 1.4M17.7 17.7l1.4 1.4M2 12h2M20 12h2M4.9 19.1l1.4-1.4M17.7 6.3l1.4-1.4" {...p} /></>,
    moon: <path d="M20 14.5A8 8 0 1 1 9.5 4a7 7 0 0 0 10.5 10.5Z" {...p} />,
    chip: <path d="M8 3h8a5 5 0 0 1 5 5v8a5 5 0 0 1-5 5H8a5 5 0 0 1-5-5V8a5 5 0 0 1 5-5Z" {...p} />,
    waveform: null, // drawn inline
    trash: <><path d="M4 7h16M9 7V4h6v3M6 7l1 13a2 2 0 0 0 2 2h6a2 2 0 0 0 2-2l1-13M10 11v7M14 11v7" {...p} /></>,
    info: <><circle cx="12" cy="12" r="9" {...p} /><path d="M12 8v.01M11 12h1v5h1" {...p} /></>,
    globe: <><circle cx="12" cy="12" r="9" {...p} /><path d="M3 12h18M12 3c3 3 3 15 0 18M12 3c-3 3-3 15 0 18" {...p} /></>,
    shield: <path d="M12 3 4 6v6c0 4 3 7 8 9 5-2 8-5 8-9V6l-8-3Z" {...p} />,
    download: <path d="M12 4v12m-5-5 5 5 5-5M5 20h14" {...p} />,
  };
  return (
    <svg width={size} height={size} viewBox="0 0 24 24" style={{ display: 'block', flexShrink: 0 }}>
      {paths[name]}
    </svg>
  );
};

Object.assign(window, { MNIcon });
