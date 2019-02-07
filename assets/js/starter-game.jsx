import React, {Fragment, Component} from 'react';
import ReactDOM from 'react-dom';
import _ from 'lodash';

import Card, {EmptyCard} from './card';

export default function game_init(root, channel) {
  ReactDOM.render(<Memory channel={channel}/>, root);
}

class Memory extends Component {
  constructor(props) {
    super(props);
    this.channel = props.channel;
    this.state = {
      matrix: [],
      showing: [],
      win: false,
      showCount: 0
    };

    this.channel
      .join()
      .receive('ok', this.gotView.bind(this))
      .receive('error', console.error);
    this.fetchData(); // TODO: ugh
  }

  // TODO: delete this because ew
  fetchData() {
    this.channel.push('get_view').receive('ok', this.gotView.bind(this));
    setTimeout(this.fetchData.bind(this), 250);
  }

  gotView({view}) {
    this.setState(_.mapKeys(view, (v, k)  => _.camelCase(k)));
  }

  resetGame() {
    this.channel
      .push('reset', {})
      .receive('ok', this.gotView.bind(this));
  }

  getHandleCardClicked(x, y) {
    return () => {
      this.channel
        .push('show', {x, y})
        .receive('ok', this.gotView.bind(this))
    };
  }

  render() {
    const {matrix, showCount, win} = this.state;

    const winMessage = win ? (
      <div className="win-message">
        Congratulations, you won in {showCount} clicks! Press Reset Game to try again.
      </div>
    ) : null;

    return (
      <Fragment>
        <div className="score">
          Clicks {showCount}
          <button className="reset" onClick={this.resetGame.bind(this)}>Reset Game</button>
        </div>
        <div className="board container">
          {winMessage}
          {matrix.map((row, y) => (
            <div className="row" key={`row-${y}`}>
              {row.map((cardValue, x) => {
                const showCard = cardValue !== 'hide';
                return cardValue !== 'delete' ?
                  <Card
                    key={`card-${x}-${y}`}
                    flip={showCard}
                    onClick={this.getHandleCardClicked(x, y)}
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

