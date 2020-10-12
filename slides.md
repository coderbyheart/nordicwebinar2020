---
title: Cloud connectivity and protocols for the Internet of Things
theme: white
slideNumber: true
header-includes: |
  <link href="https://fonts.googleapis.com/css2?family=Work+Sans:wght@200;400;500&display=swap" rel="stylesheet">
  <style>
   .reveal h1, .reveal h2, .reveal h3, .reveal h4, .reveal h5, .reveal h6 {
      font-weight: 200;
      text-transform: none;
      font-family: var(--heading-font);
   } 
   .reveal {
        font-size: var(--main-font-size);
        font-family: var(--main-font); 
        font-weight: 400;
        font-size: 32px;
   }
   .reveal strong {
        font-weight: 500;
   }
   :root {
        --main-font: 'Work Sans', sans-serif;
       --heading-font: 'Work Sans', sans-serif;
   }
   .reveal-viewport {
     background-color: #fff;
   }
   .reveal-viewport::before {
      content: "";
      position: absolute;
      top: 0; left: 0;
      width: 100%; height: 100%;
      background-image: url(graphic-to-be-filtered.jpg);
      background: url('./bg.png') no-repeat;
      background-attachment: fixed;
      background-size: cover;
      filter: blur(10px) opacity(0.1);
   }
   #speakers img {
      border-radius: 100%;
    }
  </style>
---

## Speakers

:::::::::::::: {.columns}

::: {.column width="50%"}

![Markus Tacker](https://images.contentful.com/bncv3c2gt878/6CWMgqeZdCmkk6KkIUksgQ/50922090bc6566c6624c12b82a4bf78c/36671282034_427eace68d_o.jpg){width=35%}

**Senior R&D Engineer**  
Nordic Semiconductor

<small>[Markus.Tacker@NordicSemi.no](mailto:Markus.Tacker@NordicSemi.no)  
Twitter: [\@coderbyheart](https://twitter.com/coderbyheart)</small>

:::

::: {.column width="50%"}

![Carl Richard Fosse](https://media-exp1.licdn.com/dms/image/C4E03AQEOzpPDY87zTg/profile-displayphoto-shrink_800_800/0?e=1607558400&v=beta&t=8fuZjNlQUZAJb4oLuunZ0NP5D01CL9_W4IMvifA6pjI){width=35%}

**Application Engineer**  
Nordic Semiconductor

<small>[Carl.Fosse@NordicSemi.no](mailto:Carl.Fosse@NordicSemi.no)</small>

:::

::::::::::::::

[#NordicTechWebinars](https://twitter.com/hashtag/NordicTechWebinars)

## Agenda

- Application level data
- Application level protocols
- Transport protocols
- How to measure data usage
- Wireless radio protocols
- Power consumption
- Summary
- Ways to your first proof-of-concept

## Application level data

![Typical IoT Data Protocol Configuration](./common-iot-data-protocols.jpg){width=50%}

:::notes

[Source](https://miro.com/app/board/o9J_kjPVxw8=/)

What you see here is a typical configuration for cellular IoT devices.

:::

## The four kinds of data

1. Device State
1. Device Configuration
1. Past Data
1. Firmware Updates

## 1. Device State

- **sensor readings** (like position, temperature)
- information about it's **health** (like battery level)

Because the latest state should be immediately visible: buffer data in a
_Digital&nbsp;Twin_.

:::notes

A device needs to send its sensor readings (like position, temperature) and
information about it's health to the backend, first an foremost is the battery
level a critical health indicator. This data is considered the device state.

Because we want to always be able to quickly see the latest state of the device,
a digital twin can be used to store this state on the backend side: whenever the
device sends an update, the digital twin is updated. This allows an application
to access the most recent device state immediately without needing to wait for
the device to connect and publish its state.

:::

## Update Device State only if needed

- implement situational awareness on the device
- only send **relevant** data
  - did a sensor reach a critical threshold?
  - has enough time passed since last update?
  - is the connection good enough?

:::notes

It is an important criterion for the robustness of any IoT product to gracefully
handle situations in which the device is not connected to the internet. It might
even not be favorable to be connected all the time—wireless communication is
relatively expensive consumes a lot of energy and therefore increases the power
consumption.

> To optimize for ultra-low power consumption, we want to turn off the modem as
> quickly as possible and keep it off as long as possible.

This can be achieved by making the device smart and allowing it to decide based
on the situation whether it should try to send data.

For example could an asset tracker use the motion sensor to decide whether to
publish its state frequently or if it detects no movement for a while go into a
passive mode, where it turns of the modem and waits until it detects movement
again. It could also use the internal clock to wake up every hour to sent a
heartbeat, after all we might want to know that the device is healthy, even it
is not in motion.

:::

## 2. Device Configuration

- change behaviour of device in real time (e.g. sensor sensititiy, timeouts)
- configure physical state (e.g. _locked_ state of a door lock)

:::notes

Depending on the product we might also want to change the device configuration.
This could on the one hand be use during development to tweak the aforementioned
behavior using variables instead of pushing a new firmware over the air to the
device. We observe firmware sizes of around 250 KB which will, even when
compressed, be expensive because it will take a device some time to download and
apply the updated, not to mention the costs for transferring the firmware update
over the cellular network. Especially in NB-IoT-only deployments is the data
rate low. Updating a fleet of devices with a new firmware involves orchestrating
the roll-out and observing for faults. All these challenges lead to the need to
be able to **configure the device**, which allows to tweak the behavior of the
device until the inflection point is reached: battery life vs. data granularity.
Interesting configuration options are for example the sensitivity of the motion
sensor: depending on the tracked subject what is considered "movement" can vary
greatly. Various timeout settings have an important influence on power- and
data-consumption: the time the device waits to acquire a GPS fix, or the time it
waits between sending updates when in motion.

On the other hand is device configuration needed if the device controls
something: imaging a smart lock which needs to manipulate the state of a
physical lock. The backend needs a way to tell the device which state that lock
should be in, and this setting needs to be persisted on the backend, since the
device could lose power, crash or otherwise lose the information if the lock
should be open or closed.

Here again is the digital twin used on the cloud side to store the latest
desired configuration of the device immediately, so the application does not
have to wait for the device to be connected to record the configuration change.
The implementation of the digital twin then will take care of sending only the
latest required changes to the device (all changes since the device did last
request its configuration are combined into one change) thus also minimizing the
amount of data which needs to be transferred to the device.

:::

## 3. Past Data

Cellular IoT devices need to send **data about past events**: they will be
offline most of the time.

![](./dekningskart.png)

:::notes

[Source](https://www.telenor.no/privat/dekning/)

Imagine a reindeer tracker which tracks the position of a herd. If position
updates are only collected when a cellular connection can be established there
will be an interesting observation: the reindeers are only walking along ridges,
but never in valleys. The reason is not because they don't like the valley, but
because the cellular signal does not reach deep down into remote valleys. The
GPS signal however will be received there from the tracker because satellites
are high on the horizon and can send their signal down into the valley.

There are many scenarios where cellular connection might not be available or
unreliable but reading sensors work. Robust ultra-mobile IoT products therefore
must make this a normal mode of operation: the absence of a cellular connection
must be treated as a temporary condition which will eventually resolve and until
then business as usual ensues. This means devices should keep measuring and
storing these measures in a ring-buffer or employ other strategies to decide
which data to discard once the memory limit is reached.

Once the device is successfully able to establish a connection it will then
(after publishing its most recent measurements) publish past data in batch.

On a side note: the same is true for devices that control a system. They should
have built-in decision rules and must not depend on an answer from a cloud
backend to provide the action to execute based on the current condition.

:::

## 4. Firmware Updates

- 2-3 magnitudes larger than a control message (~250 KB)
- notification via control channel (MQTT)
- download via data channel (HTTP): less overhead, supports resume

:::notes

Arguably a firmware update over the air can be seen as configuration, however
the size of a typical firmware image (250 KB) is 2-3 magnitudes larger than a
control message. Therefore it can be beneficial to treat it differently.
Typically an update is initiated by a configuration change, once acknowledged by
the device will initiate the firmware download. The download itself is done out
of band using not MQTT but HTTP(s) to reduce overhead.

Additionally firmware updates are so large compared to other messages that the
device may suspend all other operation until the firmware update has been
applied to conserve resources.

:::

## Great potential for optimization

- **initiating and maintaining network connection is magnitudes more expensive**
  compared to other device operations (for example reading a sensor value)
- **invest a substantial amount** into optimizing these when developing an
  **ultra-low power product**

:::notes

It's these messages that are exchanged between your devices and your backend
which are the most important aspect to optimize for when developing an ultra-low
power product because initiating and maintaining network connection is
relatively expensive compared to other device operations (for example reading a
sensor value).

It is therefore recommended to invest a substantial amount of time to revisit
the principles explained here and customize them to your specific needs. The
more the modem-uptime can be reduced and the smaller the total transferred
amount of data becomes, the longer your battery will last.

:::

## Application level protocols

- JSON
- Alternatives to JSON
  - Flatbuffers
  - CBOR

:::notes

Let's look at the "default" protocol for encoding application level data and
what alternatives exist to reduce the amount of data needed to transmit a
typical device message: a GPS location.

:::

## JSON

```json
{
  "v": {
    "lng": 10.414394,
    "lat": 63.430588,
    "acc": 17.127758,
    "alt": 221.639832,
    "spd": 0.320966,
    "hdg": 0
  },
  "ts": 1566042672382
}
```

"default" data protocol for IoT
([AWS](https://docs.aws.amazon.com/iot/latest/developerguide/iot-device-shadows.html),
[Azure](https://docs.microsoft.com/en-us/azure/iot-hub/iot-hub-devguide-device-twins),
[Google Cloud](https://cloud.google.com/iot/docs/how-tos/config/getting-state#api))

:::::::::::::: {.columns}

::: {.column width="50%"}

👍 human readable  
👍 schema-less (self-describing)

:::

::: {.column width="50%"}

👎 overhead

:::

::::::::::::::

:::notes

JSON offers very good support in tooling and is human readable. Especially
during development its verbosity is valuable.

:::

## Possible Optimizations

GPS location message

:::::::::::::: {.columns}

::: {.column width="50%"}

```json
{
  "v": {
    "lng": 10.414394,
    "lat": 63.430588,
    "acc": 17.127758,
    "alt": 221.639832,
    "spd": 0.320966,
    "hdg": 0
  },
  "ts": 1566042672382
}
```

:::

::: {.column width="50%"}

<br/>

```
02 36 01 37 51 4b 73 2b
d4 24 40 09 68 06 f1 81
1d b7 4f 40 11 68 cd 8f
bf b4 20 31 40 19 e6 5d
f5 80 79 b4 6b 40 21 1a
30 48 fa b4 8a d4 3f 29
00 00 00 00 00 00 00 00
09 00 e0 cf ac f6 c9 76
42
```

:::

::::::::::::::

:::::::::::::: {.columns}

::: {.column width="50%"}

JSON  
114 bytes  
<small>without newlines</small>

:::

::: {.column width="50%"}

Protocol Buffers  
65 bytes (-42%)  
<small>[source](https://gist.github.com/coderbyheart/34a8e71ffe30af882407544567971efb)</small>

:::

::::::::::::::

:::notes

Consider this GPS message. It contains a lot of data which is intended for
humans, but not needed for machines sending or receiving the data.

The pure binary message would be transmitting only the 6 floats and 1 integer of
the message. However a strucured message format is always preferred because we
also want to ensure it's integrity.

In JSON notation this document (without newlines) has 114 bytes. If the message
were to be transferred using for example Protocol Buffers the data can be
encoded with only 65 bytes (a 42% improvement).

See also:
[RION Performance Benchmarks](http://tutorials.jenkov.com/rion/rion-performance-benchmarks.html)

:::

## Flatbuffers

[google.github.io/flatbuffers](https://google.github.io/flatbuffers/)

- evolution of
  [Protocol Buffers](https://developers.google.com/protocol-buffers)
- **access a buffer without parsing**
- smaller library,
  [C implementation exists](https://github.com/dvidelabs/flatcc)
- wire format size
  [a little bigger](http://google.github.io/flatbuffers/flatbuffers_benchmarks.html)
  compared to Protocol Buffers
- schema-less (self-describing) messages are supported
- **NOT** supported in Zephyr/NCS

:::notes

In the comparison on the previous slide we showed how using Protocol Buffers can
dramatically reduce the transferred data size, while keeping a typed message.

The implementation of Protocol Buffers is however quite big (for a resource
constrained device like the nRF 9160), and no official encoder/decoder
implementation exists for C,
[inofficial does](https://github.com/protobuf-c/protobuf-c).

Flatbuffers is the best candidate with similar data savings.

Especially the ability to access members of a message directly in place makes it
ideal for memory-constrained devices: no need to create a second copy of the
received values.

It also offers flexibility during development is also supported because
FlatBuffers offers a schema-less (self-describing) version.

Unfortunately there is no official support in the nRF Connect SDK or Zephyr as
of now.

:::

## CBOR

[cbor.io](https://cbor.io/)

- maps JSON to binary structures
- zero configuration needed between exchanging parties
- support in Zephyr ([tinycbor](https://github.com/zephyrproject-rtos/tinycbor))

:::notes

Therefore the best alternative to JSON right now is CBOR.

CBOR is standard for encoding JSON data in a set of binary structures. It
reduces volume by using more compact one byte values to replace two or more
punctuation marks.

Official support is available in Zephyr.

:::

## CBOR: example

GPS location message

:::::::::::::: {.columns}

::: {.column width="50%"}

```json
{
  "v": {
    "lng": 10.414394,
    "lat": 63.430588,
    "acc": 17.127758,
    "alt": 221.639832,
    "spd": 0.320966,
    "hdg": 0
  },
  "ts": 1566042672382
}
```

:::

::: {.column width="50%"}

<br/>

```
A2 61 76 A6 63 6C 6E 67
FB 40 24 D4 2B 73 4B 51
37 63 6C 61 74 FB 40 4F
B7 1D 81 F1 06 68 63 61
63 63 FB 40 31 20 B4 BF
8F CD 68 63 61 6C 74 FB
40 6B B4 79 80 F5 5D E6
63 73 70 64 FB 3F D4 8A
B4 FA 48 30 1A 63 68 64
67 00 62 74 73 1B 00 00
01 6C 9F 6A CC FE
```

:::

::::::::::::::

:::::::::::::: {.columns}

::: {.column width="50%"}

JSON  
114 bytes  
<small>without newlines</small>

:::

::: {.column width="50%"}

CBOR  
86 bytes (-24%)  
<small>[source](http://cbor.me/)</small>

:::

::::::::::::::

## Application level protocols: Summary

Look into denser data protocols!  
**JSON is for Humans.**

- devices always™ send the same structure:  
  no need to transmit it
- less data to send
  - less money spent on data (grows linear with № of devices)
  - less energy consumed = longer device lifetime
  - lower chance of failed transmit

## Transport protocols

- MQTT+TLS
- CoAP/LWM2M+DTLS
- Comparison

:::notes

:::

## How to measure:

:::notes

[See this blog post](https://devzone.nordicsemi.com/nordic/cellular-iot-guides/b/software-and-protocols/posts/monitoring-nrf9160-data-usage-with-connectivity-statistics)

:::

## Wireless radio protocols

- LTE-m
- NB-IoT
- Comparison

:::notes

:::

## Power consumption

- Summary of my approach
- test setup and limitations
- Results

:::notes

Speaker: Carl Richard Fosse

:::

## Summary

- no silver bullet - multiple conflicting dimensions need to be considered
- highly depends on use case scenario
- ultra-low power relevant in all scenarios

:::notes

:::

## Ways to your first proof-of-concept

Get prototyping:

- [nRF Connect for Cloud](https://www.nordicsemi.com/Software-and-tools/Development-Tools/nRF-Connect-for-Cloud)
- [Docker + AWS Sample](https://github.com/coderbyheart/fw-nrfconnect-nrf-docker)
- [Bifravst](https://bifravst.gitbook.io/bifravst/)

:::notes

:::

## Thank you!

Please let us know your feedback!

:::::::::::::: {.columns}

::: {.column width="50%"}

<small>[Markus.Tacker@NordicSemi.no](mailto:Markus.Tacker@NordicSemi.no)  
Twitter: [\@coderbyheart](https://twitter.com/coderbyheart)</small>

:::

::: {.column width="50%"}

<small>[Carl.Fosse@NordicSemi.no](mailto:Carl.Fosse@NordicSemi.no)</small>

:::

::::::::::::::

[#NordicTechWebinars](https://twitter.com/hashtag/NordicTechWebinars)  
[\{DevZone](https://devzone.nordicsemi.com/)

<small>Slides: [`bit.ly/nwiotp`](http://bit.ly/nwiotp)</small>

:::notes

:::
