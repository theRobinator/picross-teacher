PAGE_NAME = 'picrossTeacher';

picross = {};
picross.markings = {
    NONE: 0,
    WHITE: 1,
    BLACK: 2
};
angular.module(PAGE_NAME, [])
    .factory('dataService', function() {
        return {};
    })
    .controller('appCtrl', ['$scope', '$timeout', 'dataService', function($scope, $timeout, dataService) {
        var applyTimeout_ = null;
        var hintQueue_ = [];
        var animationDelay_ = 50;
        var highlightedCell_ = null;
        var lastMarking_ = null;
        var focusX_, focusY_;
        
        $scope['board'] = dataService.board;
        $scope['rowLength'] = dataService.board.rows[0].length;
        $scope['hintName'] = '';
        $scope['hintExplanation'] = 'Have fun!';
        $scope['methodDescription'] = '';
        $scope['methodDescriptionVisible'] = false;
        $scope['inputDisabled'] = false;
        $scope['focusedCell'] = null;
        $scope['keyboardControls'] = true;
        
        // Render the background image after the board has rendered
        if (dataService.backgroundImage) {
            var puzzle = document.getElementsByClassName('full-puzzle')[0];
            puzzle.classList.add('image-puzzle');
            puzzle.style.backgroundImage = "url('" + dataService.backgroundImage + "')";
            window.addEventListener('resize', resizeBackgroundImage);
            resizeBackgroundImage();
        }

        /**
         * Handle a mouse click on a cell.
         */
        $scope['handleMouse'] = function(cell, $event) {
            if ($scope['inputDisabled']) {
                return;
            }
            if ($scope['keyboardControls']) {
                $scope['focusedCell'] = cell;
                for (var i = 0; i < dataService.board.rows.length; ++i) {
                    var row = dataService.board.rows[i];
                    for (var j = 0; j < row.length; ++j) {
                        if (row[j] === cell) {
                            focusX_ = j;
                            focusY_ = i;
                            break;
                        }
                    }
                }
                
            } else {
                $event.preventDefault();
                var newMarking;
                switch (cell['marking']) {
                    case picross.markings.NONE:
                        newMarking = picross.markings.BLACK;
                        break;
                    case picross.markings.WHITE:
                        newMarking = picross.markings.NONE;
                        break;
                    case picross.markings.BLACK:
                        newMarking = picross.markings.WHITE;
                        break;
                }
                markCell(cell, newMarking);
            }
        };

        /**
         * Possibly mark a cell if the user mouses over it while holding the mouse button.
         */
        $scope['handleMouseover'] = function(cell) {
            if (lastMarking_ != null && !$scope['keyboardControls']) {
                cell['marking'] = lastMarking_;
            }
        };

        /**
         * Stop active marking.
         */
        $scope['stopMarking'] = function() {
            lastMarking_ = null;
        };

        /**
         * Handle the user pressing a key.
         */
        $scope['handleKeyDown'] = function(event) {
            event.preventDefault();
            $scope['clearHighlight']();
            var currentMarking = $scope['focusedCell']['marking'];
            switch (event.keyCode) {
                case 87:  // W
                case 38:  // Up arrow
                    focusCell(focusX_, focusY_ - 1);
                    break;
                case 68:  // D
                case 39:  // Right arrow
                    focusCell(focusX_ + 1, focusY_);
                    break;
                case 83:  // S
                case 40:  // Down arrow
                    focusCell(focusX_, focusY_ + 1);
                    break;
                case 65:  // A
                case 37:  // Left arrow
                    focusCell(focusX_ - 1, focusY_);
                    break;
                case 90:  // Z
                case 188: // ,
                    markCell($scope['focusedCell'], currentMarking == picross.markings.WHITE ? picross.markings.NONE : picross.markings.WHITE);
                    break;
                case 88:  // X
                case 190: // .
                    markCell($scope['focusedCell'], currentMarking == picross.markings.BLACK ? picross.markings.NONE : picross.markings.BLACK);
                    break;
            }
            $timeout(function(){});
        };

        /**
         * Handle the user releasing a key.
         */
        $scope['handleKeyUp'] = function(event) {
            event.preventDefault();
            switch (event.keyCode) {
                // Releasing Z, X, comma, or period stops marking (releasing arrows doesn't)
                case 90:
                case 88:
                case 188:
                case 190:
                    $scope['stopMarking']();
                    break;
            }
        };

        /**
         * Get hints from the API.
         */
        $scope['getHint'] = function() {
            if (hintQueue_.length) {
                applySingleHint();
            } else {
                $scope['inputDisabled'] = true;
                getHintsFromApi(
                    function(result) {
                        if (!result.length) {
                            markPuzzleComplete();
                            return;
                        }
                        hintQueue_ = result;
                        applySingleHint();
                        $scope['inputDisabled'] = false;
                    }, function(error) {
                        displayFailure();
                        $scope['inputDisabled'] = false;
                    }
                );
            }
        };

        /**
         * Finish the puzzle.
         */
        $scope['finishPuzzle'] = function() {
            if ($scope['inputDisabled']) {
                return;
            }
            if (hintQueue_.length) {
                applyHintSeries();
            } else {
                $scope['inputDisabled'] = true;
                getHintsFromApi(
                    function(result) {
                        if (!result.length) {
                            $scope['inputDisabled'] = false;
                        } else {
                            hintQueue_ = result;
                            applyHintSeries();
                        }
                    }, function(error) {
                        displayFailure();
                    }
                );
            }
        };

        /**
         * Stop the auto-play cycle.
         */
        $scope['stopAutoPlay'] = function() {
            if (applyTimeout_) {
                $timeout.cancel(applyTimeout_);
            }
            $scope['autoPlaying'] = false;
            $scope['inputDisabled'] = false;
        };

        /**
         * Clear the highlighted cell.
         */
        $scope['clearHighlight'] = function() {
            if (highlightedCell_) {
                delete highlightedCell_.highlighted;
                highlightedCell_ = null;
            }
            if (!document.activeElement.classList.contains('puzzle-cell')) {
                $scope['focusedCell'] = null;
            }
        };

        /**
         * Show or hide the hovering method description.
         * @param {boolean} show
         */
        $scope['showMethodDescription'] = function(show) {
            $scope['methodDescriptionVisible'] = show;
        };

        /**
         * Mark a single cell.
         */
        function markCell(cell, marking) {
            lastMarking_ = marking;
            cell['marking'] = marking;
            hintQueue_.length = 0;
        }

        /**
         * Change the focus to the given cell.
         */
        function focusCell(x, y) {
            if (x < 0) {
                x = $scope['rowLength'] - 1;
            } else if (x >= $scope['rowLength']) {
                x = 0;
            }
            if (y < 0) {
                y = dataService.board.rows.length - 1;
            } else if (y >= dataService.board.rows.length) {
                y = 0;
            }
            focusX_ = x;
            focusY_ = y;
            $scope['focusedCell'] = dataService.board.rows[y][x];
            document.getElementById('cell' + ($scope['rowLength'] * y + x)).focus();
            if (lastMarking_ != null) {
                markCell($scope['focusedCell'], lastMarking_);
            }
        }

        /**
         * Apply a single hint.
         */
        function applySingleHint() {
            var nextHint = hintQueue_.shift();
            if (nextHint) {
                var cell = dataService.board.rows[nextHint.y][nextHint.x];
                cell['marking'] = nextHint.marking;
                if (highlightedCell_) {
                    $scope['clearHighlight']();
                }
                cell.highlighted = true;
                highlightedCell_ = cell;
                $scope['hintName'] = nextHint['name'];
                $scope['hintExplanation'] = nextHint['description'];
                return true;
            } else {
                return false;
            }
        }

        /**
         * Set the marking of a cell.
         */
        function applyHintSeries() {
            $scope['inputDisabled'] = true;
            if (applyTimeout_) {
                $timeout.cancel(applyTimeout_);
            }
            
            $scope['autoPlaying'] = true;
            applyTimeout_ = $timeout(applyHintInSeries, animationDelay_);
        }

        /**
         * Apply the next hint from the queue.
         */
        function applyHintInSeries() {
            if (applySingleHint()) {
                if (!hintQueue_.length) {
                    // Attempt to load more
                    getHintsFromApi(
                        function (result) {
                            if (result.length) {
                                hintQueue_ = result;
                                applyTimeout_ = $timeout(applyHintInSeries, animationDelay_);
                            } else {
                                markPuzzleComplete();
                            }
                        }, function (error) {
                            displayFailure();
                        }
                    );
                } else {
                    applyTimeout_ = $timeout(applyHintInSeries, animationDelay_);
                }
            } else {
                $scope['inputDisabled'] = false;
            }
        }

        /**
         * Mark the puzzle as completed.
         */
        function markPuzzleComplete() {
            $scope['hintExplanation'] = 'Puzzle complete.';
            $scope['clearHighlight']();
            $scope['stopAutoPlay']();
        }

        /**
         * Display a failure message.
         */
        function displayFailure() {
            $scope['hintExplanation'] = "I couldn't think of anything.";
        }

        /**
         * Call the get_hints endpoint.
         */
        function getHintsFromApi(callback, errback) {
            $scope['hintName'] = '';
            $scope['hintExplanation'] = 'Thinking...';
            callApi('/get_hints', {'board_str': dataService.board}, callback, errback);
        }

        /**
         * Helper function to call the API.
         * @param {!string} endpoint
         * @param {*} params
         * @param {!Function} callback
         * @param {!Function} errback
         */
        function callApi(endpoint, params, callback, errback) {
            var xhr = new XMLHttpRequest();
            xhr.onreadystatechange = function() {
                if (xhr.readyState == 4 && xhr.status == 200) {
                    var responseText = xhr.responseText;
                    if (responseText == null) {
                        $scope.$apply(errback.bind(null, 'Failed to call ' + endpoint));
                    } else {
                        var responseJSON = JSON.parse(responseText);
                        if (responseJSON['error']) {
                            $scope.$apply(errback.bind(null, responseJSON['error']));
                        } else {
                            $scope.$apply(callback.bind(null, responseJSON));
                        }
                    }
                } else if (xhr.readyState == 4) {
                    // The status was not 200
                    $scope.$apply(errback.bind(null, 'Failed to call ' + endpoint));
                }
            };
            
            var postData = [];
            for (var key in params) {
                if (params.hasOwnProperty(key)) {
                    var jsonParam = JSON.stringify(params[key]);
                    // Remove angular hash key
                    jsonParam = jsonParam.replace(/((,\s*)?"\$\$hashKey"\s*:\s*"[^"]+"|"\$\$hashKey"\s*:\s*"[^"]+",)/g, '');
                    postData.push(key + '=' + encodeURIComponent(jsonParam));
                }
            }
            
            xhr.open('POST', endpoint, true);
            xhr.setRequestHeader("Content-type", "application/x-www-form-urlencoded");
            xhr.send(postData.join('&'));
        }

        /**
         * Resize the background image in the table so that it fits when the user changes the window size/zoom
         */
        function resizeBackgroundImage() {
            $timeout(function() {
                var puzzle = document.getElementsByClassName('full-puzzle')[0];
                var topLeft = document.getElementsByClassName('puzzle-image')[0];
                var puzzleSize = puzzle.getBoundingClientRect();
                var topLeftSize = topLeft.getBoundingClientRect();
                var width = puzzleSize.width - topLeftSize.width;
                var height = puzzleSize.height - topLeftSize.height;
                puzzle.style.backgroundSize = width + 'px ' + height + 'px';
            }, 150);
        }
    }]);

picross.initialize = function(boardJson, backgroundImage) {
    angular.module(PAGE_NAME).run(['dataService', function(dataService) {
        dataService.board = boardJson;
        dataService.backgroundImage = backgroundImage;
    }]);
    angular.bootstrap(document.body, [PAGE_NAME])
};