import React from 'react';

export default ({flip, onClick, value}) => (
  <div className="card column" onClick={onClick}>
    <div className={"card-value-container"}>
      <div className="card-value">
        {flip ? value : " "}
      </div>
    </div>
  </div>
);

export const EmptyCard = () => (
  <div className="card column empty">
    <div className={"card-value-container"}>
      <div className="card-value"/>
    </div>
  </div>
);
