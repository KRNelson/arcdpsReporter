const { src, dest, watch, task, parallel } = require('gulp');
const elm = require('gulp-elm');
const uglify = require('gulp-uglify');
const rename = require('gulp-rename');
const sass = require('gulp-sass')(require('sass'))

const elm_ = function() {
    return src('src/Main.elm')
        .pipe(elm({ optimize: true }))
        .pipe(uglify())
        .pipe(rename({ extname: '.min.js' }))
        .pipe(dest('./build/js'))
};

const elm_FightCard = function() {
    return src('src/FightCard.elm')
        .pipe(elm({ optimize: true }))
        .pipe(uglify())
        .pipe(rename({ extname: '.min.js' }))
        .pipe(dest('./build/js'))
};

const sass_ = function() {
    return src('scss/Main.scss')
        .pipe(sass().on('error', sass.logError))
        .pipe(dest('./build/css'))
};

const sass_FightCard = function() {
    return src('scss/FightCard.scss')
        .pipe(sass().on('error', sass.logError))
        .pipe(dest('./build/css'))
};

exports.default = function() {
    watch(['./src/FightCard.elm'], elm_FightCard)
    watch(['./scss/FightCard.scss'], sass_FightCard)
}
