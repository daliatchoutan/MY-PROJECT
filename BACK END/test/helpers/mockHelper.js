const sinon = require('sinon');

const createMockReq = (overrides = {}) => ({
  body: overrides.body || {},
  params: overrides.params || {},
  query: overrides.query || {},
  headers: overrides.headers || {},
  user: overrides.user || null,
  userModel: overrides.userModel || null
});

const createMockRes = () => {
  const res = {
    statusCode: 200,
    data: null,
    status: sinon.stub().callsFake(function (code) {
      res.statusCode = code;
      return res;
    }),
    json: sinon.stub().callsFake(function (payload) {
      res.data = payload;
      return res;
    }),
    send: sinon.stub().callsFake(function (payload) {
      res.data = payload;
      return res;
    })
  };
  return res;
};

const createMockNext = () => sinon.spy();

module.exports = {
  createMockReq,
  createMockRes,
  createMockNext
};
