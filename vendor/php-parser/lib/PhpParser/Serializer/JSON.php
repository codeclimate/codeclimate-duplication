<?php
namespace PhpParser\Serializer;

use PhpParser\Node;
use PhpParser\Comment;
use PhpParser\Serializer;

class JSON implements Serializer
{
    protected $writer;

    /**
     * Constructs a JSON serializer.
     */
    public function __construct() {
    }

    public function serialize(array $nodes) {
      return $this->_serialize($nodes);
    }

    protected function _serialize($node) {
        if ($node instanceof Node) {
          $doc = array();
          $doc['nodeType'] = $node->getType();

          foreach ($node->getAttributes() as $name => $value) {
            $doc[$name] = $value;
          }

          foreach ($node as $name => $subNode) {
            if (INF === $subNode) {
              $doc[$name] = "_PHP:CONST:INF";
            } elseif (NaN === $subNode) {
              $doc[$name] = "_PHP:CONST:NaN";
            } elseif (is_string($subNode)) {
              $doc[$name] = utf8_encode($subNode);
            } elseif (is_int($subNode)) {
              $doc[$name] = $subNode;
            } elseif (is_float($subNode)) {
              $doc[$name] = $subNode;
            } elseif (true === $subNode) {
              $doc[$name] = $subNode;
            } elseif (false === $subNode) {
              $doc[$name] = $subNode;
            } elseif (null === $subNode) {
              $doc[$name] = $subNode;
            } elseif (null !== $subNode) {
              $doc[$name] = $this->_serialize($subNode);
            }
          }

          return $doc;
        } elseif ($node instanceof Comment) {
          $doc = array();
          $doc['nodeType'] = 'comment';
          $doc['isDocComment'] = $node instanceof Comment\Doc ? true : false;
          $doc['line'] = $node->getLine();
          $doc['text'] = $node->getText();
          return $doc;
        } elseif (is_array($node)) {
          $doc = array();

          foreach ($node as $subNode) {
            $doc[] = $this->_serialize($subNode);
          }

          return $doc;
        } elseif (is_string($node)) {
          return utf8_encode($node);
        } elseif (is_int($node)) {
          return $node;
        } elseif (is_float($node)) {
          return $node;
        } elseif (true === $node) {
          return $node;
        } elseif (false === $node) {
          return $node;
        } elseif (null === $node) {
          return $node;
        } else {
          throw new \InvalidArgumentException('Unexpected node type');
        }
    }
}
