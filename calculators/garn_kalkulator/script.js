// Håndter enhetsvalg
let selectedUnit = 'meter';

const unitButtons = document.querySelectorAll('.unit-btn');
unitButtons.forEach(button => {
    button.addEventListener('click', function() {
        unitButtons.forEach(btn => btn.classList.remove('active'));
        this.classList.add('active');
        selectedUnit = this.dataset.unit;

        // Skjul resultat når enhet endres
        document.getElementById('result').classList.remove('show');
    });
});

// Håndter beregning
const calculateBtn = document.querySelector('.calculate-btn');
calculateBtn.addEventListener('click', calculateYarn);

// Tillat Enter-tast for beregning
document.querySelectorAll('input').forEach(input => {
    input.addEventListener('keypress', function(e) {
        if (e.key === 'Enter') {
            calculateYarn();
        }
    });
});

function calculateYarn() {
    const lengdeOppskrift = parseFloat(document.getElementById('lengde-oppskrift').value);
    const antallOppskrift = parseFloat(document.getElementById('antall-oppskrift').value);
    const lengdeDitt = parseFloat(document.getElementById('lengde-ditt').value);

    // Valider input
    if (!lengdeOppskrift || !antallOppskrift || !lengdeDitt) {
        alert('Vennligst fyll inn alle feltene');
        return;
    }

    if (lengdeOppskrift <= 0 || antallOppskrift <= 0 || lengdeDitt <= 0) {
        alert('Alle verdier må være større enn 0');
        return;
    }

    // Beregn totalt garn som trengs
    const totaltGarn = lengdeOppskrift * antallOppskrift;

    // Beregn antall nøster av ditt garn
    const antallNoster = totaltGarn / lengdeDitt;

    // Vis resultat
    const unitText = selectedUnit === 'meter' ? 'm' : 'yards';
    const resultText = `Du trenger ${antallNoster.toFixed(1)} nøster med løpelengde ${lengdeDitt}${unitText}`;

    document.getElementById('result-text').textContent = resultText;
    document.getElementById('result').classList.add('show');
}