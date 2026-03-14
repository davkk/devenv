local snippet = require "core.snippet"

snippet.add(
    "desc",
    [[
describe('${1}', () => {
    ${2}
});
]],
    { buffer = 0 }
)

snippet.add(
    "its",
    [[
it('${1}', () => {
    ${2}
});
]],
    { buffer = 0 }
)

snippet.add(
    "ita",
    [[
it('${1}', async () => {
    ${2}
});
]],
    { buffer = 0 }
)

snippet.add(
    "itf",
    [[
it('${1}', () => {
    const fixture = factory();
    ${3}
});
]],
    { buffer = 0 }
)

snippet.add(
    "tests",
    [[
import { TestBed } from '@angular/core/testing';

describe('${1}', () => {
    let service: ${2};

    beforeEach(() => {
        TestBed.configureTestingModule({
            providers: [${2}]
        });

        service = TestBed.inject(${2});
    });

    it('should create', () => {
        expect(service).toBeTruthy();
    });
});
]],
    { buffer = 0 }
)

snippet.add(
    "testc",
    [[
import { TestBed } from '@angular/core/testing';
import { MockInstance, MockRenderFactory } from 'ng-mocks';

describe('${1}', () => {
    MockInstance.scope();

    const factory = MockRenderFactory(${2}, []);

    beforeEach(async () => {
        TestBed.configureTestingModule({
            declarations: [${2}]
        }).compileComponents();

        factory.configureTestBed();
    });

    it('should create', () => {
        const fixture = factory(),
            { componentInstance: component } = fixture.point;

        expect(component).toBeTruthy();
    });
});
]],
    { buffer = 0 }
)

snippet.add(
    "angs",
    [[
import { Injectable } from '@angular/core';

@Injectable({ providedIn: ${1:'root'} })
export class ${2:ServiceName}Service {
    constructor() { }
}
]],
    { buffer = 0 }
)

snippet.add(
    "angc",
    [[
import { Component, OnInit } from '@angular/core';

@Component({
    selector: '${1:selector-name}',
    templateUrl: '${2:name}.component.html'
})
export class ${3:Name}Component implements OnInit {
    constructor() { }
}
]],
    { buffer = 0 }
)
