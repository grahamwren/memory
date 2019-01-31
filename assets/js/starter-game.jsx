import React, {Fragment, Component} from 'react';
import ReactDOM from 'react-dom';
import _ from 'lodash';

import Card, {EmptyCard} from './card';

const HIDE_DELAY = 1000;

export default function game_init(root) {
  ReactDOM.render(<Memory/>, root);
}

const getCards = _.memoize(n => _.times(n * n / 2, i => String.fromCharCode(i + 65)));
const getBoard = n => _.chunk(_.shuffle([...getCards(n), ...getCards(n)]), n);
const orMap = a => a.reduce((acc, v) => acc || v, false);
const getSize = defaultV => {
  const size = Number(prompt(
    `What size game do you want? (Must be even, defaults to ${defaultV})` ,
    `${defaultV}`)
  ) || defaultV;
  return (size % 2) === 0 ? size : size + 1;
};

const getMemoryStartState = () => ({
  win: false,
  clicks: 0,
  boardCards: getBoard(getSize(4)),
  showingCards: []
});

class Memory extends Component {
  constructor(props) {
    super(props);
    this.state = getMemoryStartState();
  }

  componentDidUpdate() {
    const {win, clicks} = this.state;
    if (win && confirm(`You won in ${clicks} clicks! Would you like to play again?`)) {
      return this.resetGame();
    }
  }

  resetGame() {
    this.setState(getMemoryStartState());
  }

  getHandleCardClicked(x, y, value) {
    return () => {
      if (this.state.showingCards.length > 1) return;

      if (this.state.showingCards.length === 1) {
        setTimeout(() => {
          const [card1, card2] = this.state.showingCards;
          if (card1.value === card2.value)
            this.removeCards(card1, card2);

          this.setState({
            ...this.state,
            showingCards: []
          });
        }, HIDE_DELAY);
      }

      this.setState({
        ...this.state,
        clicks: this.state.clicks + 1,
        showingCards: this.state.showingCards.concat([{x, y, value}])
      });
    };
  }

  removeCards(...cards) {
    const boardCards = this.state.boardCards;
    cards.forEach(({x, y}) => {
      boardCards[y][x] = null;
    });
    this.setState({...this.state, boardCards, win: !orMap(_.flatten(boardCards))});
  }

  render() {
    const {boardCards, clicks, showingCards: [showCard1, showCard2]} = this.state;

    return (
      <Fragment>
        <div className="score">
          Clicks {clicks}
          <button className="reset" onClick={this.resetGame.bind(this)}>Reset Game</button>
        </div>
        <div className="board container">
          {boardCards.map((row, y) => (
            <div className="row" key={`row-${y}`}>
              {row.map((cardValue, x) => {
                const curCard = {x, y, value: cardValue};
                const showCard = _.isEqual(curCard, showCard1) || _.isEqual(curCard, showCard2);
                return cardValue ?
                  <Card
                    key={`card-${x}-${y}`}
                    flip={showCard}
                    onClick={this.getHandleCardClicked(x, y, cardValue)}
                    value={cardValue}
                  /> :
                  <EmptyCard
                    key={`card-${x}-${y}`}
                  />;
              })}
            </div>
          ))}
        </div>
      </Fragment>
    );
  }
}

