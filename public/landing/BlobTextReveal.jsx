// Blob Text Reveal — Originkit (plain-JS build, rAF tweens, no framer-motion)
const { useCallback, useEffect, useLayoutEffect, useMemo, useRef, useState } = React;

const START_Y = 18;
const WIPE_STRETCH = 1.75;
const DEFORM_MS = 150;
const CHAR_REVEAL_MS = 500;
const POST_PARK_SETTLE = 400;
const WIPE_SPEED = 720;
const REVEAL_SPEED = 740;
const EASE_OUT_CUBIC = [0.215, 0.61, 0.355, 1];

function cubicBezier(x1, y1, x2, y2) {
  const cx = 3 * x1, bx = 3 * (x2 - x1) - cx, ax = 1 - cx - bx;
  const cy = 3 * y1, by = 3 * (y2 - y1) - cy, ay = 1 - cy - by;
  const sampleX = (t) => ((ax * t + bx) * t + cx) * t;
  const sampleY = (t) => ((ay * t + by) * t + cy) * t;
  const dX = (t) => (3 * ax * t + 2 * bx) * t + cx;
  return (p) => {
    let t = p;
    for (let i = 0; i < 8; i++) {
      const x = sampleX(t) - p;
      const d = dX(t);
      if (Math.abs(x) < 1e-4 || Math.abs(d) < 1e-6) break;
      t -= x / d;
    }
    return sampleY(t < 0 ? 0 : t > 1 ? 1 : t);
  };
}
const EASE_DEFORM = cubicBezier.apply(null, EASE_OUT_CUBIC);

function tween({ from, to, duration, ease, onUpdate, onComplete }) {
  let raf = 0;
  let stopped = false;
  const start = performance.now();
  const dur = Math.max(1, duration);
  const step = (now) => {
    if (stopped) return;
    const p = Math.min(1, (now - start) / dur);
    const v = from + (to - from) * (ease ? ease(p) : p);
    onUpdate && onUpdate(v);
    if (p < 1) {
      raf = requestAnimationFrame(step);
    } else if (onComplete) {
      onComplete();
    }
  };
  raf = requestAnimationFrame(step);
  return {
    stop() {
      stopped = true;
      cancelAnimationFrame(raf);
    }
  };
}

const travel = (distance, speed, min, max) => {
  if (!isFinite(distance) || distance <= 0) return min;
  return Math.min(max, Math.max(min, (distance / speed) * 1000));
};

const splitChars = (text) => Array.from(text);

const prefersReducedMotion = () =>
  typeof window !== "undefined" && window.matchMedia("(prefers-reduced-motion: reduce)").matches;

function BlobTextReveal(props) {
  const {
    texts = ["TEXT", "REVEAL"],
    font = { fontFamily: "inherit", fontSize: "48px", fontWeight: 500, letterSpacing: "0em", lineHeight: "1.1em", textAlign: "center" },
    color = "#ffffff",
    wipeColor = "#d66e54",
    revealColor = "#9bc8b5",
    blobSize = 12,
    blobPosition = -2,
    blur = 14,
    holdMs = 2200,
    style
  } = props;

  const safeBlobSize = Math.min(Math.max(blobSize, 4), 24);
  const safeTexts = useMemo(() => {
    const list = (texts || []).filter((t) => t && t.length > 0);
    return list.length > 0 ? list : ["TEXT"];
  }, [texts]);

  const [wordIndex, setWordIndex] = useState(0);
  const wordIndexRef = useRef(0);
  const wrapperRef = useRef(null);
  const charsRef = useRef([]);
  const blobRef = useRef(null);
  const blobStateRef = useRef({ x: 0, w: safeBlobSize });

  const currentWord = safeTexts[wordIndex] || safeTexts[0] || "";
  const characters = useMemo(() => splitChars(currentWord), [currentWord]);

  useLayoutEffect(() => {
    charsRef.current.length = characters.length;
  }, [characters.length, currentWord]);

  const nextFrame = () => new Promise((r) => requestAnimationFrame(() => r()));

  const paintBlob = useCallback(() => {
    const el = blobRef.current;
    if (!el) return;
    const s = blobStateRef.current;
    el.style.width = s.w + "px";
    el.style.transform = "translateX(" + (s.x - s.w / 2) + "px)";
  }, []);

  const setBlobColor = useCallback((c) => {
    if (blobRef.current) blobRef.current.style.backgroundColor = c;
  }, []);

  const measure = useCallback(() => {
    const wrapper = wrapperRef.current;
    if (!wrapper) return null;
    const nodes = charsRef.current.filter(Boolean);
    if (!nodes.length) return null;
    const layoutWidth = wrapper.offsetWidth;
    if (layoutWidth < 1) return null;
    const half = safeBlobSize / 2;
    const clearGap = Math.max(6, Math.round(safeBlobSize * 0.45));
    const parkInset = half + clearGap;
    const chars = nodes.map((node) => {
      const left = node.offsetLeft;
      const width = node.offsetWidth;
      return { left, right: left + width, center: left + width / 2 };
    });
    if (chars.some((c) => c.right <= c.left)) return null;
    const first = chars[0];
    const last = chars[chars.length - 1];
    return {
      chars,
      nodes,
      homeX: last.right + parkInset,
      leftX: Math.max(half, first.left - parkInset)
    };
  }, [safeBlobSize]);

  const measureRef = useRef(measure);
  measureRef.current = measure;

  const waitForLayout = useCallback(async () => {
    for (let i = 0; i < 40; i++) {
      await nextFrame();
      const layout = measureRef.current();
      if (layout) return layout;
    }
    return null;
  }, []);

  const showChars = useCallback((nodes) => {
    nodes.forEach((n) => {
      n.style.transition = "none";
      n.style.opacity = "1";
      n.style.filter = "blur(0px)";
      n.style.transform = "translateY(0px)";
    });
  }, []);

  const hideChars = useCallback(
    (nodes) => {
      nodes.forEach((n) => {
        n.style.transition = "none";
        n.style.opacity = "0";
        n.style.filter = "blur(" + blur + "px)";
        n.style.transform = "translateY(" + START_Y + "px)";
      });
    },
    [blur]
  );

  useEffect(() => {
    let cancelled = false;
    let anim = null;
    let deform = null;
    let timer = null;

    const wait = (ms) =>
      new Promise((resolve) => {
        timer = setTimeout(resolve, ms);
      });

    const deformTo = (mode) => {
      deform && deform.stop();
      const target = mode === "wipe" ? safeBlobSize * WIPE_STRETCH : safeBlobSize;
      return new Promise((resolve) => {
        deform = tween({
          from: blobStateRef.current.w,
          to: target,
          duration: DEFORM_MS,
          ease: EASE_DEFORM,
          onUpdate: (w) => {
            blobStateRef.current.w = w;
            paintBlob();
          },
          onComplete: resolve
        });
      });
    };

    const revealChar = (node) => {
      node.style.transition =
        "opacity " + CHAR_REVEAL_MS + "ms cubic-bezier(.215,.61,.355,1), filter " + CHAR_REVEAL_MS + "ms cubic-bezier(.215,.61,.355,1), transform " + CHAR_REVEAL_MS + "ms cubic-bezier(.215,.61,.355,1)";
      node.style.opacity = "1";
      node.style.filter = "blur(0px)";
      node.style.transform = "translateY(0px)";
    };

    const run = async () => {
      let layout = await waitForLayout();
      if (!layout || cancelled) return;

      if (prefersReducedMotion()) {
        blobStateRef.current = { x: layout.homeX, w: safeBlobSize };
        paintBlob();
        setBlobColor(revealColor);
        showChars(layout.nodes);
        return;
      }

      blobStateRef.current = { x: layout.homeX, w: safeBlobSize };
      paintBlob();
      setBlobColor(revealColor);
      showChars(layout.nodes);

      while (!cancelled) {
        layout = await waitForLayout();
        if (!layout || cancelled) break;

        await wait(holdMs);
        if (cancelled) break;

        // wipe: blob sweeps right to left, hiding characters behind its lead edge
        setBlobColor(wipeColor);
        void deformTo("wipe");
        const wipeDistance = Math.abs(layout.homeX - layout.leftX);
        const wipeMs = travel(wipeDistance, WIPE_SPEED, 350, 550);
        let shrunk = false;
        const wipeNodes = layout.nodes;
        const wipeChars = layout.chars;
        await new Promise((resolve) => {
          anim = tween({
            from: layout.homeX,
            to: layout.leftX,
            duration: wipeMs,
            onUpdate: (x) => {
              blobStateRef.current.x = x;
              paintBlob();
              const lead = x - blobStateRef.current.w / 2;
              wipeNodes.forEach((node, i) => {
                const m = wipeChars[i];
                if (!m) return;
                if (lead <= m.right) {
                  node.style.transition = "none";
                  node.style.opacity = "0";
                  node.style.filter = "blur(" + blur + "px)";
                  node.style.transform = "translateY(" + START_Y + "px)";
                }
              });
              if (!shrunk && wipeDistance > 0 && Math.abs(layout.homeX - x) / wipeDistance >= 0.82) {
                shrunk = true;
                void deformTo("rest");
                setBlobColor(revealColor);
              }
            },
            onComplete: () => {
              if (!shrunk) {
                void deformTo("rest");
                setBlobColor(revealColor);
              }
              resolve();
            }
          });
        });
        if (cancelled) break;

        // swap to the next variation
        const nextIndex = (wordIndexRef.current + 1) % safeTexts.length;
        wordIndexRef.current = nextIndex;
        setWordIndex(nextIndex);
        await nextFrame();
        await nextFrame();
        const rl = measureRef.current();
        if (!rl || cancelled) break;

        hideChars(rl.nodes);
        blobStateRef.current.x = rl.leftX;
        paintBlob();

        // reveal: blob sweeps left to right, uncovering each character
        const revealed = new Set();
        const revealMs = travel(Math.abs(rl.homeX - rl.leftX), REVEAL_SPEED, 350, 750);
        await new Promise((resolve) => {
          anim = tween({
            from: rl.leftX,
            to: rl.homeX,
            duration: revealMs,
            onUpdate: (x) => {
              blobStateRef.current.x = x;
              paintBlob();
              const lead = x + blobStateRef.current.w / 2;
              rl.nodes.forEach((node, i) => {
                if (revealed.has(i)) return;
                const m = rl.chars[i];
                if (m && lead >= m.left) {
                  revealed.add(i);
                  revealChar(node);
                }
              });
            },
            onComplete: () => {
              rl.nodes.forEach((node, i) => {
                if (!revealed.has(i)) {
                  revealed.add(i);
                  revealChar(node);
                }
              });
              timer = setTimeout(resolve, POST_PARK_SETTLE);
            }
          });
        });
        if (cancelled) break;
        showChars(rl.nodes);
        blobStateRef.current.x = rl.homeX;
        paintBlob();
      }
    };

    run();

    return () => {
      cancelled = true;
      clearTimeout(timer);
      anim && anim.stop();
      deform && deform.stop();
    };
  }, [safeTexts, holdMs, blur, safeBlobSize, revealColor, wipeColor, paintBlob, setBlobColor, showChars, hideChars, waitForLayout]);

  const textAlign = font.textAlign || "center";
  const justifyContent = textAlign === "center" ? "center" : textAlign === "right" ? "flex-end" : "flex-start";

  return (
    <div
      style={{
        ...font,
        width: "100%",
        display: "flex",
        alignItems: "center",
        justifyContent,
        textAlign,
        ...style
      }}
    >
      <span
        ref={wrapperRef}
        style={{
          position: "relative",
          display: "inline-block",
          color,
          letterSpacing: font.letterSpacing || "0em",
          lineHeight: font.lineHeight || 1.1,
          paddingRight: Math.max(6, Math.round(safeBlobSize * 0.45)) + safeBlobSize
        }}
      >
        <span aria-hidden="true" style={{ display: "inline-block", whiteSpace: "pre" }}>
          {characters.map((char, i) => (
            <span
              key={currentWord + "-" + i}
              ref={(node) => {
                charsRef.current[i] = node;
              }}
              style={{ display: "inline-block", transformOrigin: "50% 50%", willChange: "transform, opacity, filter" }}
            >
              {char === " " ? "\u00A0" : char}
            </span>
          ))}
        </span>
        <span style={{ position: "absolute", width: 1, height: 1, padding: 0, margin: -1, overflow: "hidden", clip: "rect(0,0,0,0)", whiteSpace: "nowrap" }}>
          {currentWord}
        </span>
        <span
          ref={blobRef}
          aria-hidden="true"
          style={{
            position: "absolute",
            bottom: "0.08em",
            left: 0,
            width: safeBlobSize,
            height: safeBlobSize,
            marginBottom: Math.round(safeBlobSize * 0.55) + blobPosition,
            borderRadius: 9999,
            backgroundColor: revealColor,
            display: "block",
            pointerEvents: "none",
            willChange: "transform, width, background-color"
          }}
        />
      </span>
    </div>
  );
}

module.exports = { BlobTextReveal };
