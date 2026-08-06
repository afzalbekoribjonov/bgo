interface QtyStepperProps {
  value: number;
  onDecrement: () => void;
  onIncrement: () => void;
  decrementDisabled?: boolean;
  incrementDisabled?: boolean;
}

export default function QtyStepper({
  value,
  onDecrement,
  onIncrement,
  decrementDisabled,
  incrementDisabled,
}: QtyStepperProps) {
  return (
    <div className="qty-stepper">
      <button onClick={onDecrement} disabled={decrementDisabled} aria-label="Kamaytirish">
        −
      </button>
      <span className="qty-val">{value}</span>
      <button onClick={onIncrement} disabled={incrementDisabled} aria-label="Ko'paytirish">
        +
      </button>
    </div>
  );
}
