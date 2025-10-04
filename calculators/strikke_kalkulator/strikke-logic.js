/**
 * Jevn fordeling av øk/fell i strikking
 * - evenStitchesAcrossRow: fordel X øk/fell jevnt over en rad/omgang
 * - evenOverRows: fordel X øk/fell jevnt over R rader (to intervaller)
 *
 * Kilder/idé:
 *  - Jevn plassering i én rad/omgang + "+1-segment" i flat strikk: 10 Rows A Day
 *  - Jevn plassering over flere rader (to rater): Ysoldas "magic formula"
 */

/** Fordel endringer jevnt over maskene i en rad/omgang.
 * @param {number} totalSts  Antall masker på pinnen nå.
 * @param {number} changes   Antall øk/fell du vil gjøre.
 * @param {{type:'increase'|'decrease', flat:boolean}} opts
 *  - type: 'increase' (øk) eller 'decrease' (fell)
 *  - flat: true for flat strikk (rad), false for rundstrikk (omgang)
 * @returns {{
 *   segments:number[],
 *   steps: Array<{work:number, action:'inc'|'dec'|null}>,
 *   instruction:string
 * }}
 *
 * Prinsipp:
 *  - Antall segmenter = changes + 1 ved flat strikk (for pen symmetri), ellers = changes.
 *  - Fordel totalSts på segmentene slik at forskjellen maks er 1 maske (Bresenham-fordeling).
 *  - ØK: strikk hele segmentet, så øk (unntatt etter siste segment).
 *  - FELL: strikk til de siste 2 av segmentet (eller 0 hvis segment<2), så fell.
 */
function evenStitchesAcrossRow(totalSts, changes, opts = { type: 'increase', flat: true }) {
  if (!Number.isFinite(totalSts) || !Number.isFinite(changes) || changes < 1)
    throw new Error('Ugyldige tall.');

  const type = opts.type || 'increase';
  const flat = !!opts.flat;

  const segmentsCount = flat ? changes + 1 : changes;
  if (segmentsCount < 1) throw new Error('For få segmenter.');

  const base = Math.floor(totalSts / segmentsCount);
  const remainder = totalSts % segmentsCount;

  // Bresenham-lignende fordeling av remainder for mest mulig jevn spredning
  const segments = Array(segmentsCount).fill(base);
  let err = 0;
  for (let i = 0; i < segmentsCount; i++) {
    err += remainder;
    if (err >= segmentsCount) {
      segments[i] += 1;
      err -= segmentsCount;
    }
  }

  // Bygg konkrete «strikk X, [øk/fell], strikk Y …»-steg
  const steps = [];
  if (type === 'increase') {
    for (let i = 0; i < segments.length; i++) {
      steps.push({ work: segments[i], action: i < segments.length - 1 ? 'inc' : null });
    }
  } else {
    // decrease: strikk hele segmentet, så fell (samme som increase)
    for (let i = 0; i < segments.length; i++) {
      steps.push({ work: segments[i], action: i < segments.length - 1 ? 'dec' : null });
    }
  }

  // Lag en kort, lesbar instruksjon
  const incWord = type === 'increase' ? 'øk' : 'fell';
  let instruction = buildNorwegianInstruction(steps, segments, changes, type, flat, incWord);

  return { segments, steps, instruction };
}

function buildNorwegianInstruction(steps, segments, changes, type, flat, incWord) {
  // Bygg norsk instruksjon med gruppering av like segmenter
  const lines = [];

  let i = 0;
  while (i < steps.length) {
    const step = steps[i];

    // Siste segment uten action
    if (!step.action) {
      if (step.work > 0) {
        lines.push(`Strikk ${step.work} ${step.work === 1 ? 'maske' : 'masker'}`);
      }
      break;
    }

    // Hopp over segmenter med 0 masker - bare øk/fell uten strikk
    if (step.work === 0) {
      // Tell hvor mange påfølgende 0-segmenter
      let count = 1;
      while (i + count < steps.length - 1 &&
             steps[i + count].work === 0 &&
             steps[i + count].action === step.action) {
        count++;
      }

      if (count > 1) {
        lines.push(`*${incWord.charAt(0).toUpperCase() + incWord.slice(1)} 1 maske* ${count} ${count === 1 ? 'gang' : 'ganger'}`);
      } else {
        lines.push(`${incWord.charAt(0).toUpperCase() + incWord.slice(1)} 1 maske`);
      }
      i += count;
      continue;
    }

    // Tell hvor mange påfølgende like segmenter
    let count = 1;
    while (i + count < steps.length - 1 &&
           steps[i + count].work === step.work &&
           steps[i + count].action === step.action) {
      count++;
    }

    if (count > 1) {
      // Bruk repetisjon
      lines.push(`*Strikk ${step.work} ${step.work === 1 ? 'maske' : 'masker'}, ${incWord} 1 maske* ${count} ${count === 1 ? 'gang' : 'ganger'}`);
      i += count;
    } else {
      // Enkelt segment
      lines.push(`Strikk ${step.work} ${step.work === 1 ? 'maske' : 'masker'}, ${incWord} 1 maske`);
      i++;
    }
  }

  return lines.join('\n');
}

/** Fordel endringer jevnt over R rader (Ysolda "magic formula").
 * @param {number} totalRows Antall rader du har til selve formingen.
 * @param {number} changes   Antall ganger du skal øke/felle i høyden.
 * @returns {{
 *   low:number, high:number,
 *   countLow:number, countHigh:number,
 *   intervals:number[],
 *   summary:string
 * }}
 *
 * Idé: bruk to intervaller: low = ⌊R/D⌋ og high = ⌈R/D⌉.
 * Antall high = R - low*D; resten er low. Plasser high så jevnt som mulig (Bresenham).
 */
function evenOverRows(totalRows, changes) {
  if (!Number.isFinite(totalRows) || !Number.isFinite(changes) || changes < 1)
    throw new Error('Ugyldige tall.');

  const low = Math.floor(totalRows / changes);
  const high = Math.ceil(totalRows / changes);
  const countHigh = totalRows - low * changes;
  const countLow = changes - countHigh;

  // Bygg intervallrekkefølge (mellom hver endring) med jevn spredning av "high"
  const intervals = [];
  let placedHigh = 0;
  for (let i = 0; i < changes; i++) {
    // fordel high jevnt ved å se om (i+1)*countHigh > (placedHigh+1)*changes
    const shouldHigh = (i + 1) * countHigh > (placedHigh + 1) * changes;
    if (shouldHigh) {
      intervals.push(high);
      placedHigh++;
    } else {
      intervals.push(low);
    }
  }

  // Oppsummer for mønstertekst
  const parts = [];
  if (countLow > 0) parts.push(`hver ${low}. rad ${countLow} gang${countLow === 1 ? '' : 'er'}`);
  if (countHigh > 0) parts.push(`hver ${high}. rad ${countHigh} gang${countHigh === 1 ? '' : 'er'}`);
  const summary =
    parts.length
      ? `Arbeid øk/fell ${parts.join(' og ')}, fordelt omtrent slik: ${intervals.join('-')}.`
      : `Arbeid øk/fell hver ${low}. rad ${changes} ganger.`;

  return { low, high, countLow, countHigh, intervals, summary };
}