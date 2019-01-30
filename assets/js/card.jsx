import React from 'react';

export default function Card({flip, onClick, value}) {
  return <div className="card" onClick={onClick}>{flip ? value : " "}</div>
}

export const EmptyCard = () => <div className="card empty"/>;
